// Retire le splash dès que Flutter a rendu son premier frame
window.addEventListener('flutter-first-frame', function () {
  var splash = document.getElementById('splash');
  if (splash) splash.remove();
});

// Filet de sécurité : retrait forcé après 15s (si événement non reçu)
setTimeout(function () {
  var splash = document.getElementById('splash');
  if (splash) splash.remove();
}, 15000);
