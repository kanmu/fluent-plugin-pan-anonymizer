require 'fluent/plugin/filter'
require 'fluent/plugin/pan/masker'

module Fluent::Plugin
  class PANAnonymizerFilter < Filter
    Fluent::Plugin.register_filter("pan_anonymizer", self)

    config_section :pan, param_name: :pan_configs, required: true, multi: true do
      config_param :formats,            :array,  value_type: :regexp, default: []
      config_param :checksum_algorithm, :enum,   list: Fluent::PAN::Masker::CHECKSUM_FUNC.keys, default: :luhn
      config_param :mask,               :string, default: "****"
      config_param :force,              :bool,   default: false
    end
    config_param :ignore_keys,          :array,  default: []

    def initialize
      super
    end

    def configure(conf)
      super

      formats = conf.each_element.map do |i|
        next if i["formats"].nil?
        i["formats"].scan(/\/[^\/]*\//).map do |j| j.delete("/") end.map do |j| Regexp.new(j) end
      end.flatten

      @pan_masker = @pan_configs.map do |i|
        formats.map do |format|
          Fluent::PAN::Masker.new(format, i[:checksum_algorithm], i[:mask], i[:force])
        end
      end.flatten
    end

    def filter(tag, time, record)
      record.map do |key, value|
        if @ignore_keys.include? key.to_s
          [key, value]
        else
          _value = value
          @pan_masker.each do |i|
            _value = i.mask_if_found_pan(_value)
          end
          [key, _value]
        end
      end.to_h
    end
  end
end
