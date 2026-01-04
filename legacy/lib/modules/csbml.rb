module Csbml

  def with_csbml
    apply_csbml(yield)
  end

  SMILEYS = [
      {name: 'fröhlich', filename: 'laechel.gif', expr: /:(\-)?\)/i, shortcut: ':)'},
      {name: 'traurig', filename: 'traurig.gif', expr: /:(\-)?\(/i, shortcut: ':('},
      {name: 'zwinker', filename: 'zwinker.gif', expr: /;(\-)?\)/i, shortcut: ';)'},
      {name: 'cool', filename: 'cool.gif', expr: /8\-\)/i, shortcut: '8-)'},
      {name: 'ätsch', filename: 'aetsch.gif', expr: /:\-p/i, shortcut: ':-p'},
      {name: 'weinend', filename: 'heul.gif', expr: ':cry:', shortcut: ':cry:'},
      {name: 'grins', filename: 'grins.gif', expr: /:(\-)?D/i, shortcut: ':D'},
      {name: 'verwirrt', filename: 'verwirrt.gif', expr: /:\-S/i, shortcut: ':-s'},
      {name: 'überrascht', filename: 'ueberrascht.gif', expr: /:\-o/i, shortcut: ':-O'},
      {name: 'wütend', filename: 'wuetend.gif', expr: ':boese:', shortcut: ':boese:'},
      {name: 'unschuldig', filename: 'unschuldig.gif', expr: ':unschuldig:', shortcut: ':unschuldig:'},
      {name: 'hmm', filename: 'hmm.gif', expr: ':-/', shortcut: ':-/'},
      {name: 'schaem.gif', filename: 'schaem.gif', expr: ':schaem:', shortcut: ':schaem:'},
      {name: 'ausschenken', filename: 'ausschenken.gif', expr: ':ausschenken:', shortcut: ':ausschenken:'},
      {name: 'hurra', filename: 'hurra.gif', expr: ':hurra:', shortcut: ':hurra:'},
      {name: 'lala', filename: 'lala.gif', expr: ':lala:', shortcut: ':lala:'},
      {name: 'lol', filename: 'lol.gif', expr: ':lol:', shortcut: ':lol:'},
      {name: 'party', filename: 'party.gif', expr: ':party:', shortcut: ':party:'},
      {name: 'stösschen', filename: 'stoesschen.gif', expr: ':stoesschen:', shortcut: ':stoesschen:'},
      {name: 'super', filename: 'super.gif', expr: ':super:', shortcut: ':super:'},
      {name: 'tröst', filename: 'troest.gif', expr: ':troest:', shortcut: ':troest:'},
      {name: 'vogel', filename: 'vogel.gif', expr: ':vogel:', shortcut: ':vogel:'},
      {name: 'wink', filename: 'wink.gif', expr: ':wink:', shortcut: ':wink:'},
      {name: 'gelage', filename: 'gelage.gif', expr: ':gelage:', shortcut: ':gelage:'},
      {name: 'kater', filename: 'kater.gif', expr: ':kater:', shortcut: ':kater:'}
  ]

  protected

    def apply_csbml(text)
      csbml_bold(text)
      csbml_underline(text)
      csbml_italic(text)
      csbml_color(text)
      csbml_quote(text)
      csbml_url(text)
      csbml_image(text)
      csbml_smileys(text)
    end

    def csbml_bold(text)
      opening_tag = /\[b\]/i
      closing_tag = /\[\/b\]/i
      if (text.scan(opening_tag).count == text.scan(closing_tag).count)
        text.gsub!(opening_tag, '<strong>')
        text.gsub!(closing_tag, '</strong>')
      end
      return text
    end

    def csbml_underline(text)
      opening_tag = /\[u\]/i
      closing_tag = /\[\/u\]/i
      if (text.scan(opening_tag).count == text.scan(closing_tag).count)
        text.gsub!(opening_tag, '<u>')
        text.gsub!(closing_tag, '</u>')
      end
      return text
    end

    def csbml_italic(text)
      opening_tag = /\[i\]/i
      closing_tag = /\[\/i\]/i
      if (text.scan(opening_tag).count == text.scan(closing_tag).count)
        text.gsub!(opening_tag, '<i>')
        text.gsub!(closing_tag, '</i>')
      end
      return text
    end

    def csbml_color(text)
      opening_tag = /\[color=(.*?)\]/i
      closing_tag = /\[\/color\]/i
      if (text.scan(opening_tag).count == text.scan(closing_tag).count)
        text.gsub!(opening_tag, '<span style="color:\\1;">')
        text.gsub!(closing_tag, '</span>')
      end
      return text
    end

    def csbml_quote(text)
      opening_tag = /\[quote (.*?)\]/i
      closing_tag = /\[\/quote\]/i
      if (text.scan(opening_tag).count == text.scan(closing_tag).count)
        text.gsub!(opening_tag, '<div class="quote"><div class="author">\\1 schrieb:</div><div class="quoting">')
        text.gsub!(closing_tag, '</div></div>')
      end
      return text
    end

    def csbml_url(text)
      opening_tag = /\[url=(.*?)\]/i
      closing_tag = /\[\/url\]/i
      if (text.scan(opening_tag).count == text.scan(closing_tag).count)
        text.gsub!(opening_tag, '<a href="\\1" target="_blank" rel="nofollow">')
        text.gsub!(closing_tag, '</a>')
      end
      return text
    end

    def csbml_image(text)
      text.gsub!(/\[img\](.*?)\[\/img\]/i, '<img src="\\1" />')
    end

    def csbml_smileys(text)
      SMILEYS.each do |smiley|
        text.gsub!(smiley[:expr], ActionController::Base.helpers.image_tag('smileys/' + smiley[:filename]))
      end

      return text
    end

end