/* THE WOMEN — site behaviour. Settings live in js/config.js. */
(function () {
  'use strict';
  var cfg = window.SITE_CONFIG || {};
  var $ = function (s, r) { return (r || document).querySelector(s); };
  var $$ = function (s, r) { return Array.prototype.slice.call((r || document).querySelectorAll(s)); };

  /* ---------- 1. Fill in settings from config.js ---------- */
  $$('[data-cfg-text]').forEach(function (el) {
    var v = cfg[el.getAttribute('data-cfg-text')];
    if (v) el.textContent = v;
  });
  $$('[data-cfg-text-upper]').forEach(function (el) {
    var v = cfg[el.getAttribute('data-cfg-text-upper')];
    if (v) el.textContent = v.toUpperCase();
  });
  $$('[data-cfg-href]').forEach(function (el) {
    var v = cfg[el.getAttribute('data-cfg-href')];
    if (v) el.setAttribute('href', v);
  });
  $$('[data-cfg-mailto]').forEach(function (el) {
    var v = cfg[el.getAttribute('data-cfg-mailto')];
    if (v) el.setAttribute('href', 'mailto:' + v);
  });
  /* ---------- 2. Book cover (falls back to placeholder) ---------- */
  var coverImg = $('#book-cover-img'), placeholder = $('#cover-placeholder');
  if (coverImg && cfg.bookCover) {
    var probe = new Image();
    probe.onload = function () {
      coverImg.src = cfg.bookCover;
      coverImg.alt = cfg.bookCoverAlt || 'Book cover of ' + (cfg.bookTitle || 'the book');
      coverImg.hidden = false;
      if (placeholder) placeholder.hidden = true;
    };
    probe.onerror = function () { /* keep the placeholder visible */ };
    probe.src = cfg.bookCover;
  }

  /* ---------- 3. Mobile menu ---------- */
  var toggle = $('.nav-toggle'), menu = $('#nav-menu');
  function setMenu(open) {
    menu.classList.toggle('open', open);
    toggle.setAttribute('aria-expanded', String(open));
    toggle.setAttribute('aria-label', open ? 'Close menu' : 'Open menu');
  }
  toggle.addEventListener('click', function () { setMenu(!menu.classList.contains('open')); });
  $$('a', menu).forEach(function (a) { a.addEventListener('click', function () { setMenu(false); }); });
  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape' && menu.classList.contains('open')) { setMenu(false); toggle.focus(); }
  });
  document.addEventListener('click', function (e) {
    if (menu.classList.contains('open') && !e.target.closest('.nav')) setMenu(false);
  });
  window.addEventListener('resize', function () { if (window.innerWidth > 900) setMenu(false); });

  /* ---------- 4. Highlight current section in nav ---------- */
  var links = $$('.nav-menu a[href^="#"]:not(.btn)');
  var sections = links.map(function (a) { return $(a.getAttribute('href')); }).filter(Boolean);
  if ('IntersectionObserver' in window && sections.length) {
    var spy = new IntersectionObserver(function (entries) {
      entries.forEach(function (en) {
        if (en.isIntersecting) {
          links.forEach(function (a) {
            var on = a.getAttribute('href') === '#' + en.target.id;
            a.classList.toggle('active', on);
            if (on) a.setAttribute('aria-current', 'true'); else a.removeAttribute('aria-current');
          });
        }
      });
    }, { rootMargin: '-45% 0px -50% 0px' });
    sections.forEach(function (s) { spy.observe(s); });
  }

  /* ---------- 5. Reveal on scroll ---------- */
  var reveals = $$('.reveal');
  var reduce = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  if (reduce || !('IntersectionObserver' in window)) {
    reveals.forEach(function (el) { el.classList.add('in'); });
  } else {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (en) { if (en.isIntersecting) { en.target.classList.add('in'); io.unobserve(en.target); } });
    }, { threshold: 0.12 });
    reveals.forEach(function (el) { io.observe(el); });
  }

  /* ---------- 6. Contact form ---------- */
  var form = $('#contact-form'), status = $('#form-status');
  var EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;

  function setError(input, msg) {
    var field = input.closest('.field'), err = $('.error', field);
    err.textContent = msg || '';
    field.classList.toggle('invalid', !!msg);
    if (msg) input.setAttribute('aria-invalid', 'true'); else input.removeAttribute('aria-invalid');
  }
  function validate() {
    var f = form.elements, bad = null;
    var name = f.name.value.trim(), email = f.email.value.trim(), msg = f.message.value.trim();
    setError(f.name, name ? '' : 'Please enter your name.');
    setError(f.email, !email ? 'Please enter your email address.' : (EMAIL_RE.test(email) ? '' : 'Please enter a valid email address.'));
    setError(f.message, msg.length >= 10 ? '' : (msg ? 'Please write at least 10 characters.' : 'Please write a message.'));
    ['name', 'email', 'message'].some(function (k) { if (f[k].getAttribute('aria-invalid')) { bad = f[k]; return true; } });
    return bad;
  }
  function say(text, cls) { status.textContent = text; status.className = 'form-status ' + (cls || ''); }

  ['name', 'email', 'message'].forEach(function (k) {
    form.elements[k].addEventListener('input', function () { if (this.getAttribute('aria-invalid')) validate(); });
  });

  form.addEventListener('submit', function (e) {
    e.preventDefault();
    say('');
    var firstBad = validate();
    if (firstBad) { firstBad.focus(); return; }
    if (form.elements._gotcha.value) return; // spam bot

    var data = {
      name: form.elements.name.value.trim(),
      email: form.elements.email.value.trim(),
      message: form.elements.message.value.trim()
    };

    // Option A: a form service is connected (see README)
    if (cfg.formEndpoint) {
      var btn = $('button[type=submit]', form); btn.disabled = true; say('Sending…');
      fetch(cfg.formEndpoint, {
        method: 'POST', headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' }, body: JSON.stringify(data)
      }).then(function (r) {
        if (!r.ok) throw new Error('bad response');
        form.reset(); say('Thank you! Your message has been sent.', 'ok');
      }).catch(function () {
        say('Sorry, something went wrong. Please try again, or email directly.', 'bad');
      }).then(function () { btn.disabled = false; });
      return;
    }

    // Option B: no service yet, but a real email is set -> open the visitor's email app
    if (cfg.email && !/example\.com$/i.test(cfg.email)) {
      var body = data.message + '\n\n— ' + data.name + ' (' + data.email + ')';
      window.location.href = 'mailto:' + cfg.email + '?subject=' + encodeURIComponent('Message from ' + data.name) + '&body=' + encodeURIComponent(body);
      say('Opening your email app to send the message…', 'ok');
      return;
    }

    // Option C: nothing connected yet — be honest, don't pretend it was sent
    say('Your details look good, but this form is not connected to an email service yet, so nothing was sent. (Site owner: see README.md.)', 'warn');
  });
})();
