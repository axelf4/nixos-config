{ iosevka }: iosevka.override {
  set = "custom";
  privateBuildPlan = ''
    [buildPlans.iosevka-custom]
    family = "Iosevka"
    spacing = "fixed"
    no-cv-ss = true

    [buildPlans.iosevka-custom.variants.design]
    g = "double-storey-open"
    asterisk = "penta-low"
    number-sign = "upright-open"
    at = "short"

    [buildPlans.iosevka-custom.weights]
    regular = "default.regular"
    bold = "default.bold"
    [buildPlans.iosevka-custom.slopes]
    upright = "default.upright"
    italic = "default.italic"
    [buildPlans.iosevka-custom.widths]
    normal = "default.normal"
  '';
}
