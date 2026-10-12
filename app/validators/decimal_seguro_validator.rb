class DecimalSeguroValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    raw = record.public_send("#{attribute}_before_type_cast")
    return if raw.blank? && options[:allow_nil]

    numero = BigDecimal(raw.to_s, exception: false)
    escala = options.fetch(:scale, 2)
    limite = BigDecimal("10")**(10 - escala)
    if numero.nil? || !numero.finite? || numero.abs >= limite || numero != numero.round(escala)
      record.errors.add(attribute, "deve ser um número válido com até #{escala} casas decimais e menor que #{limite.to_i}")
    end
  end
end
