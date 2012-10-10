module Formattable
  def fields_for_document(object, model)
    fields = [:account_id, :user_id, :first_name, :last_name, :name, :email, :email2,
      :home_email, :phone, :mobile, :home_phone, :updated_at, :content]

    obj_fields = { :model => model }
    fields.each do |field|
      

      # TODO Clean this up?
      # If note, use created_by_user_id
      if model == 'note' and field == :user_id then
        obj_fields[field.to_s] = object['created_by_user_id'] if object['created_by_user_id'].present?
      # If numerical field, strip non-numeric characters
      elsif [:phone, :mobile, :home_phone].include? field then
        obj_fields[field.to_s] = object[field.to_s].gsub(/[^0-9]/i, '') if object[field.to_s].present?
      else
        obj_fields[field.to_s] = encode_text(object[field.to_s]) if object[field.to_s].present?
      end
    end
    obj_fields
  end

  private

  def encode_text(text)
    if text.respond_to? :encoding
      encoding_options = {
        :invalid           => :replace,  # Replace invalid byte sequences
        :undef             => :replace,  # Replace anything not defined in ASCII
        :replace           => '',        # Use a blank for those replacements
        :newline           => :universal # Always break lines with \n
      }

      text = text.gsub(/[^\x20-\x7e]/,'')
        .encode('UTF-8')
        .gsub(/[^\u0009\u000a\u000d\u0020-\uD7FF\uE000-\uFFFD]/, '')
        .encode(encoding_options)
    end
    text
  end
end