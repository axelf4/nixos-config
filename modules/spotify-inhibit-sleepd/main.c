/**
 * Daemon that works around the fact that Spotify does not inhibit
 * sleep while playing audio, by monitoring D-Bus for changes in
 * playback status.
 */

#include <stdio.h>
#include <glib.h>
#include <gio/gio.h>

enum InhibitFlags {
	INHIBIT_LOGOUT = 1 << 0,
	INHIBIT_SWITCH = 1 << 1,
	INHIBIT_SUSPEND = 1 << 2,
	INHIBIT_IDLE = 1 << 3,
};

struct State {
	GDBusConnection *session;
	GDBusProxy *inhibit_proxy;
	char *inhibit_handle,
		*current_name;
};

static void inhibit(struct State *st) {
	if (st->inhibit_handle) return;
	GVariantBuilder options;
	g_variant_builder_init(&options, G_VARIANT_TYPE_VARDICT);
	g_variant_builder_add(&options, "{sv}", "reason", g_variant_new_string("Spotify is playing audio"));
	GVariant *res;
	if (!(res = g_dbus_proxy_call_sync(
				st->inhibit_proxy,
				"Inhibit",
				g_variant_new("(su@a{sv})", /* window */ "", INHIBIT_SUSPEND,
					g_variant_builder_end(&options)),
				G_DBUS_CALL_FLAGS_NONE, G_MAXINT, NULL, NULL))) return;
	g_variant_get(res, "(o)", &st->inhibit_handle);
	g_variant_unref(res);
}

static void uninhibit(struct State *st) {
	if (!st->inhibit_handle) return;
	g_dbus_connection_call(
		st->session,
		"org.freedesktop.portal.Desktop",
		st->inhibit_handle,
		"org.freedesktop.portal.Request",
		"Close",
		g_variant_new("()"), G_VARIANT_TYPE_UNIT,
		G_DBUS_CALL_FLAGS_NONE, G_MAXINT, NULL, NULL, NULL);
	g_free(st->inhibit_handle);
	st->inhibit_handle = NULL;
}

static void on_properties_changed(GDBusConnection *c,
								  const gchar *sender_name, const gchar *object_path,
								  const gchar *interface_name, const gchar *signal_name,
								  GVariant *parameters, gpointer user_data) {
	struct State *st = user_data;
	GVariant *changed_properties;
	g_variant_get(parameters, "(s@a{sv}as)", NULL, &changed_properties, NULL);
	if (!g_variant_n_children(changed_properties)) return;

	GVariantIter *iter;
	g_variant_get(changed_properties, "a{sv}", &iter);
	const gchar *key;
	GVariant *value;
	while (g_variant_iter_loop(iter, "{&sv}", &key, &value)) {
		if (strcmp(key, "PlaybackStatus") != 0) continue;

		gboolean is_playing = strcmp(g_variant_get_string(value, NULL), "Playing") == 0;
		if (is_playing) {
			inhibit(st);
			g_free(st->current_name);
			st->current_name = g_strdup(sender_name);
		} else uninhibit(st);
	}
	g_variant_iter_free(iter);
}

/**
 * Callback for when the org.mpris.MediaPlayer2.spotify name owner changed.
 *
 * Spotify cannot run multiple instances which makes things simpler:
 * If it lost its name then Spotify can no longer be playing.
 */
static void on_name_owner_changed(GDBusConnection *c,
								  const gchar *sender_name, const gchar *object_path,
								  const gchar *interface_name, const gchar *signal_name,
								  GVariant *parameters, gpointer user_data) {
	struct State *st = user_data;
	const gchar *old_owner, *new_owner;
	g_variant_get(parameters, "(s&s&s)", NULL, &old_owner, &new_owner);
	if (!(st->current_name && strcmp(old_owner, st->current_name) == 0)) return;

	if (new_owner[0] != '\0') {
		g_free(st->current_name);
		st->current_name = g_strdup(new_owner);
	} else uninhibit(st);
}

gint main(gint argc, gchar *argv[]) {
	GError *error = NULL;
	GDBusConnection *session;
	if (!(session = g_bus_get_sync(G_BUS_TYPE_SESSION, NULL, &error))) {
		fprintf(stderr, "g_bus_get_sync error: %s\n", error->message);
		return 1;
	}
	GDBusProxy *inhibit_proxy;
	if (!(inhibit_proxy = g_dbus_proxy_new_sync(
			  session, G_DBUS_PROXY_FLAGS_NONE, NULL,
			  "org.freedesktop.portal.Desktop",
			  "/org/freedesktop/portal/desktop",
			  "org.freedesktop.portal.Inhibit",
			  NULL, &error))) {
		fprintf(stderr, "g_dbus_proxy_new_sync error: %s\n", error->message);
		return 1;
	}
	struct State st = { .session = session, .inhibit_proxy = inhibit_proxy };

	g_dbus_connection_signal_subscribe(
		session,
		"org.mpris.MediaPlayer2.spotify",
		"org.freedesktop.DBus.Properties",
		"PropertiesChanged",
		"/org/mpris/MediaPlayer2",
		"org.mpris.MediaPlayer2.Player", G_DBUS_SIGNAL_FLAGS_NONE,
		on_properties_changed, &st, NULL);
	g_dbus_connection_signal_subscribe(
		session,
		"org.freedesktop.DBus",
		"org.freedesktop.DBus",
		"NameOwnerChanged",
		"/org/freedesktop/DBus",
		"org.mpris.MediaPlayer2.spotify", G_DBUS_SIGNAL_FLAGS_NONE,
		on_name_owner_changed, &st, NULL);

	GMainLoop *loop = g_main_loop_new(NULL, FALSE);
	g_main_loop_run(loop);
	__builtin_unreachable();
}
