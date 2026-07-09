// ZenZoo landing — behaviour ported from the design's DCLogic component.
(function () {
  'use strict';

  // Reveal on scroll
  var reduceMotion = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  if ('IntersectionObserver' in window && !reduceMotion) {
    var els = Array.prototype.slice.call(document.querySelectorAll('[data-reveal]'));
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (en) {
        if (!en.isIntersecting) return;
        var el = en.target;
        io.unobserve(el);
        var wait = parseInt(el.getAttribute('data-rd') || '0', 10);
        setTimeout(function () {
          el.style.opacity = '1';
          el.style.transform = el.dataset.zzTf || 'translateY(0px) scale(1)';
          var done = function () {
            el.style.opacity = '';
            el.style.transform = el.dataset.zzTf || '';
            el.style.transition = el.dataset.zzTs || '';
          };
          el.addEventListener('transitionend', done, { once: true });
          setTimeout(done, 950);
        }, wait);
      });
    }, { threshold: 0.12, rootMargin: '0px 0px -36px 0px' });
    els.forEach(function (el) {
      el.dataset.zzTf = el.style.transform || '';
      el.dataset.zzTs = el.style.transition || '';
      el.style.opacity = '0';
      el.style.transform = 'translateY(26px) scale(0.985)';
      el.style.transition = 'opacity .7s cubic-bezier(.33,1,.68,1), transform .7s cubic-bezier(.33,1,.68,1)';
      io.observe(el);
    });
  }

  // Billing toggle (monthly / yearly, default yearly)
  var mBtn = document.getElementById('zz-bill-monthly');
  var yBtn = document.getElementById('zz-bill-yearly');
  var price = document.getElementById('zz-pro-price');
  var unit = document.getElementById('zz-pro-unit');
  var note = document.getElementById('zz-pro-note');
  function setBilling(yearly) {
    mBtn.style.background = yearly ? 'transparent' : '#FFFFFF';
    mBtn.style.color = yearly ? '#5E7A88' : '#1F4E74';
    mBtn.style.boxShadow = yearly ? 'none' : '0 3px 10px rgba(34,102,152,.16)';
    yBtn.style.background = yearly ? '#FFFFFF' : 'transparent';
    yBtn.style.color = yearly ? '#1F4E74' : '#5E7A88';
    yBtn.style.boxShadow = yearly ? '0 3px 10px rgba(34,102,152,.16)' : 'none';
    price.textContent = yearly ? '279.000đ' : '29.000đ';
    unit.textContent = yearly ? '/năm' : '/tháng';
    note.textContent = yearly ? 'Chỉ ≈ 23.000đ/tháng — tiết kiệm 20% 🎉' : 'Mẹo: gói năm 279.000đ tiết kiệm 20%';
  }
  if (mBtn && yBtn && price && unit && note) {
    mBtn.addEventListener('click', function () { setBilling(false); });
    yBtn.addEventListener('click', function () { setBilling(true); });
  }

  // FAQ chevron rotation
  Array.prototype.forEach.call(document.querySelectorAll('#faq details'), function (d) {
    d.addEventListener('toggle', function () {
      var c = d.querySelector('[data-chev]');
      if (c) c.style.transform = d.open ? 'rotate(45deg)' : 'rotate(0deg)';
    });
  });
})();
