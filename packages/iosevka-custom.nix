{ iosevka }: iosevka.override {
  set = "Custom";
  privateBuildPlan = ''
    [buildPlans.IosevkaCustom]
    family = "Iosevka"
    spacing = "fixed"
    noCvSs = true
    weights = { Regular = "default.Regular", Bold = "default.Bold" }
    slopes = { Upright = "default.Upright", Italic = "default.Italic" }
    widths = { Normal = "default.Normal" }

    [buildPlans.IosevkaCustom.variants.design]
    g = "double-storey-open"
    asterisk = "penta-low"
    number-sign = "upright-open"
    at = "compact"
  '';
}
