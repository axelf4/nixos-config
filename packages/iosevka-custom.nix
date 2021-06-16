{ iosevka }: iosevka.override {
  set = "custom";
  privateBuildPlan = ''
    [buildPlans.iosevka-custom]
    family = "Iosevka"
    spacing = "fixed"
    no-cv-ss = true

    [buildPlans.iosevka-custom.variants.design]
    g = "double-storey-open"
    asterisk = "low" # Renamed to penta-low in v6.0
    number-sign = "upright-open"
    at = "short"

    [buildPlans.iosevka-custom.weights.regular]
    shape = 400
    menu = 400
    css = 400
    [buildPlans.iosevka-custom.weights.bold]
    shape = 700
    menu = 700
    css = 700
    [buildPlans.iosevka-custom.slopes]
    upright = "normal"
    italic = "italic"
    [buildPlans.iosevka-custom.widths.normal]
    shape = 500
    menu = 5
    css = "normal"
  '';
}
