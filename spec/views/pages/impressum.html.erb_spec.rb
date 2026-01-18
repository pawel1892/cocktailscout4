require 'rails_helper'

RSpec.describe "pages/impressum.html.erb", type: :view do
  it "renders the impressum page" do
    render
    expect(rendered).to match /Impressum/
    expect(rendered).to match /Angaben gemäß § 5 TMG/
  end
end
