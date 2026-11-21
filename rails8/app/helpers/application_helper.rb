module ApplicationHelper
  def md(text)
    simple_format(text.to_s.strip)
  end

  def code(text)
    content_tag(:pre, text.to_s)
  end
end
