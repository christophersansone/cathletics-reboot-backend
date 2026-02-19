LegendaryJsonApi::Config.key_transform = -> (value) { value.to_s.camelize(:lower) }
LegendaryJsonApi::Config.id_transform = -> (value) { value.to_s }
