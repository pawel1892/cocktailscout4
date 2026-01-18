require 'rails_helper'

RSpec.describe "pages/datenschutz.html.erb", type: :view do
  it "renders the datenschutz page" do
    render
    expect(rendered).to match /Datenschutzerklärung/
    expect(rendered).to match /Datenschutz auf einen Blick/
  end
end
