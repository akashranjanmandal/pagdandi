#!/usr/bin/env python3
"""Builds the self-contained D2 prototypes (../<name>.html) from src/<name>.src.html.

CSS and icon sprite are extracted from ../components.html (the D1 source of truth), so
tokens and components can never drift. Run: python3 docs/design/src/build.py
"""
import re, pathlib
here = pathlib.Path(__file__).parent
out = here.parent
comp = (out / 'components.html').read_text()
css = re.search(r'<style>(.*?)</style>', comp, re.S).group(1)
sprite = re.search(r'(<svg width="0".*?</svg>)', comp, re.S).group(1)
extra_icons = '''
  <symbol id="i-chev" viewBox="0 0 24 24"><path d="M9 6l6 6-6 6"/></symbol>
  <symbol id="i-walk" viewBox="0 0 24 24"><circle cx="13" cy="4.5" r="1.8"/><path d="M11 21l2-6-3-3 1-4 4 2 2 3M8 12l-2 3"/></symbol>
  <symbol id="i-stay" viewBox="0 0 24 24"><rect x="5" y="5" width="14" height="14" rx="3"/><circle cx="12" cy="12" r="2"/></symbol>
  <symbol id="i-call" viewBox="0 0 24 24"><path d="M5 4h4l2 5-2.5 1.5a11 11 0 005 5L15 13l5 2v4a2 2 0 01-2 2A16 16 0 013 6a2 2 0 012-2z"/></symbol>
  <symbol id="i-card" viewBox="0 0 24 24"><rect x="3" y="5" width="18" height="14" rx="2"/><path d="M7 10h4M7 14h6M16 10v.01"/></symbol>
  <symbol id="i-cold" viewBox="0 0 24 24"><path d="M12 3v18M5 7l14 10M19 7L5 17"/></symbol>
  <symbol id="i-moon" viewBox="0 0 24 24"><path d="M20 14A8 8 0 019.500 4 8 8 0 1020 14z"/></symbol>
  <symbol id="i-bolt" viewBox="0 0 24 24"><path d="M13 3L5 14h6l-1 7 8-11h-6z"/></symbol>
'''
sprite = sprite.replace('</defs>', extra_icons + '</defs>')
sprite = re.sub(r'(\d)\.(\d)00\b', r'\1.\2', sprite)
extra_css = (here / 'phone.css').read_text()
base_js = (here / 'base.js').read_text()
links = [('setup', 'Setup'), ('basecamp', 'Basecamp'), ('emergency-card', 'Emergency card'), ('lock-notification', 'Lock screen'), ('active-trek', 'Active Trek'), ('lost-mode', 'Lost mode'), ('friend-sos', 'Friend SOS'),
         ('fall-countdown', 'Fall countdown'), ('sos-active', 'SOS active'), ('components', 'Components')]
toggles = [('sun', 'Sunlight'), ('glove', 'Glove'), ('left', 'Left-handed'),
           ('reduce', 'Reduce motion'), ('ts', 'Text 1.5×')]
for src in sorted(here.glob('*.src.html')):
    name = src.name.replace('.src.html', '')
    cur = ' aria-current="page"'
    nav = ''.join('<a href="%s.html"%s>%s</a>' % (n, cur if n == name else '', t) for n, t in links)
    tg = ''.join(f'<button class="tg" data-p="{k}" aria-pressed="false">{t}</button>' for k, t in toggles)
    bar = f'<div class="bar" role="toolbar" aria-label="Preview options"><nav class="navlinks">{nav}</nav><span style="flex:1"></span>{tg}</div>'
    html = src.read_text()
    for k, v in {'{{CSS}}': css + extra_css, '{{SPRITE}}': sprite, '{{BASE_JS}}': base_js, '{{BAR}}': bar}.items():
        html = html.replace(k, v)
    (out / f'{name}.html').write_text(html)
    print('built', name)
