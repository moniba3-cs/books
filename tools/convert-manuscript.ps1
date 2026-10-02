param(
  [string]$InputPath = 'D:\The_Women.docx',
  [string]$OutputPath = (Join-Path $PSScriptRoot '..\book.html')
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

$archive = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $InputPath))
try {
  $documentEntry = $archive.GetEntry('word/document.xml')
  $documentReader = [System.IO.StreamReader]::new($documentEntry.Open())
  try { [xml]$document = $documentReader.ReadToEnd() }
  finally { $documentReader.Dispose() }

  $script:namespaces = [System.Xml.XmlNamespaceManager]::new($document.NameTable)
  $script:namespaces.AddNamespace('w', 'http://schemas.openxmlformats.org/wordprocessingml/2006/main')

  function Convert-Run {
    param([System.Xml.XmlNode]$Run)

    $text = [System.Text.StringBuilder]::new()
    foreach ($token in $Run.SelectNodes('./w:t | ./w:tab | ./w:br', $script:namespaces)) {
      if ($token.LocalName -eq 't') {
        [void]$text.Append([System.Net.WebUtility]::HtmlEncode($token.InnerText))
      } elseif ($token.LocalName -eq 'tab') {
        [void]$text.Append('&#9;')
      } else {
        [void]$text.Append('<br>')
      }
    }

    $formatted = $text.ToString()
    if ($Run.SelectSingleNode('./w:rPr/w:i', $script:namespaces)) { $formatted = '<em>' + $formatted + '</em>' }
    if ($Run.SelectSingleNode('./w:rPr/w:b', $script:namespaces)) { $formatted = '<strong>' + $formatted + '</strong>' }
    $formatted
  }

  $body = [System.Text.StringBuilder]::new()
  $listOpen = $false
  foreach ($paragraph in $document.SelectNodes('//w:body/w:p', $script:namespaces)) {
    $styleNode = $paragraph.SelectSingleNode('./w:pPr/w:pStyle', $script:namespaces)
    $styleId = if ($styleNode) { $styleNode.GetAttribute('val', 'http://schemas.openxmlformats.org/wordprocessingml/2006/main') } else { '1' }
    if ($styleId -in @('16', '17')) { continue }

    $content = [System.Text.StringBuilder]::new()
    foreach ($node in $paragraph.ChildNodes) {
      if ($node.LocalName -eq 'r') {
        [void]$content.Append((Convert-Run $node))
      } elseif ($node.LocalName -eq 'hyperlink') {
        foreach ($run in $node.SelectNodes('./w:r', $script:namespaces)) {
          [void]$content.Append((Convert-Run $run))
        }
      }
    }
    $paragraphHtml = $content.ToString()
    if (-not $paragraphHtml.Trim()) { continue }

    $numbered = $paragraph.SelectSingleNode('./w:pPr/w:numPr', $script:namespaces)
    if ($numbered) {
      if (-not $listOpen) {
        [void]$body.AppendLine('<ul class="manuscript-list">')
        $listOpen = $true
      }
      [void]$body.AppendLine('<li>' + $paragraphHtml + '</li>')
      continue
    }
    if ($listOpen) {
      [void]$body.AppendLine('</ul>')
      $listOpen = $false
    }

    switch ($styleId) {
      '2' { [void]$body.AppendLine('<h2 class="part-heading">' + $paragraphHtml + '</h2>') }
      '3' { [void]$body.AppendLine('<h3 class="chapter-heading">' + $paragraphHtml + '</h3>') }
      '15' { [void]$body.AppendLine('<h1>' + $paragraphHtml + '</h1>') }
      default { [void]$body.AppendLine('<p>' + $paragraphHtml + '</p>') }
    }
  }
  if ($listOpen) { [void]$body.AppendLine('</ul>') }

  $html = @'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="theme-color" content="#4a2a22">
  <title>BOOKies | Read The Women</title>
  <link rel="icon" type="image/svg+xml" href="assets/favicon.svg">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:wght@400;500;600;700&family=Lora:ital,wght@0,400;0,500;0,600;1,400&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="css/style.css">
  <style>
    .reader-header { padding: 2.5rem 0 2rem; text-align: center; background: var(--blush-2); border-bottom: 1px solid var(--line); }
    .reader-header h1 { margin: 1.2rem 0 .1rem; font-size: clamp(2.5rem, 8vw, 4rem); }
    .reader-author { margin: 0; color: var(--rose-brown); font-style: italic; }
    .reader-main { width: min(760px, 100% - 2.5rem); margin: 2.5rem auto 5rem; }
    .reader-gate { max-width: 540px; margin: 4rem auto; padding: 0 1rem; text-align: center; }
    .reader-gate h2 { margin-bottom: .8rem; }
    .reader-gate p { color: var(--choc-soft); }
    .reader-gate-actions { display: flex; flex-wrap: wrap; justify-content: center; gap: .8rem; margin-top: 1.5rem; }
    .reader-note { font-size: .9rem; }
    .review-dialog { width: min(560px, calc(100% - 2rem)); max-height: min(90vh, 760px); padding: 0; color: var(--choc); background: var(--cream); border: 1px solid var(--line); box-shadow: 0 24px 80px rgba(30, 20, 16, .35); }
    .review-dialog::backdrop { background: rgba(34, 24, 21, .68); }
    .review-form { padding: clamp(1.25rem, 4vw, 2rem); }
    .review-dialog-head { display: flex; justify-content: space-between; align-items: flex-start; gap: 1rem; margin-bottom: 1.3rem; }
    .review-dialog-head h2 { margin: 0; }
    .review-close { flex: none; padding: .25rem .55rem; border: 1px solid var(--line); border-radius: 4px; background: transparent; color: var(--choc); font: inherit; font-size: 1.3rem; cursor: pointer; }
    .review-field { margin-bottom: 1rem; }
    .review-field label { display: block; margin-bottom: .3rem; font-weight: 600; }
    .review-field input, .review-field textarea { width: 100%; padding: .7rem .8rem; border: 1px solid var(--line); border-radius: 4px; background: #fff; color: var(--choc); font: inherit; }
    .review-field textarea { min-height: 150px; resize: vertical; }
    .review-email-link { display: inline-block; margin-top: 1rem; }
    .review-status { margin: .8rem 0 0; font-size: .95rem; }
    .manuscript { padding: clamp(1.5rem, 6vw, 4rem); background: #fffaf3; border: 1px solid var(--line); box-shadow: var(--shadow); }
    .manuscript > h1:first-child { text-align: center; font-size: 2.4rem; }
    .manuscript > h2.part-heading { margin: 3rem 0 1.2rem; padding-top: 1.2rem; border-top: 1px solid var(--line); font-size: 2.2rem; }
    .manuscript > h3.chapter-heading { margin: 2rem 0 .9rem; font-size: 1.65rem; }
    .manuscript > p { line-height: 1.9; }
    .manuscript-list { padding-left: 1.5rem; margin: .5rem 0 1.2rem; }
    .manuscript-list li { padding-left: .3rem; margin: .35rem 0; }
    .reader-footer { display: flex; justify-content: center; gap: .8rem; flex-wrap: wrap; margin: 2rem 0; }
    @media (max-width: 560px) { .manuscript { padding: 1.25rem; } }
  </style>
</head>
<body>
  <header class="reader-header">
    <a class="btn btn-small btn-secondary" href="index.html#home">BOOKies home</a>
    <h1>The Women</h1>
    <p class="reader-author">Monibah Mehmood</p>
  </header>
  <main class="reader-main">
    <section class="reader-gate" id="reader-gate" aria-labelledby="reader-gate-title">
      <p class="eyebrow">Step 1</p>
      <h2 id="reader-gate-title">Follow to read</h2>
      <p>Follow on Instagram, then return here and confirm to open the full book.</p>
      <div class="reader-gate-actions">
        <a class="btn btn-primary" href="https://instagram.com/mrtvilo._" target="_blank" rel="noopener noreferrer">Follow on Instagram<span class="sr-only"> (opens in a new tab)</span></a>
        <button class="btn btn-secondary" id="unlock-book" type="button">I followed - continue</button>
      </div>
      <p class="reader-note">This website cannot verify Instagram follows; the confirmation is on your honor.</p>
    </section>
    <article class="manuscript" aria-label="The full text of The Women" tabindex="-1" hidden>
__MANUSCRIPT__
    </article>
    <nav class="reader-footer" aria-label="Reader links" hidden>
      <a class="btn btn-secondary" href="https://instagram.com/mrtvilo._" target="_blank" rel="noopener noreferrer">Follow on Instagram</a>
      <button class="btn btn-primary" id="open-review" type="button">Write a review</button>
    </nav>
  </main>
  <dialog class="review-dialog" id="review-dialog" aria-labelledby="review-title">
    <form class="review-form" id="review-form">
      <div class="review-dialog-head">
        <div><p class="eyebrow">Reader Review</p><h2 id="review-title">Share your thoughts</h2></div>
        <button class="review-close" id="close-review" type="button" aria-label="Close review form">×</button>
      </div>
      <div class="review-field"><label for="review-name">Your name</label><input id="review-name" name="name" autocomplete="name" required></div>
      <div class="review-field"><label for="review-email">Your email</label><input id="review-email" name="email" type="email" autocomplete="email" required></div>
      <div class="review-field"><label for="review-message">Your review</label><textarea id="review-message" name="review" required minlength="10"></textarea></div>
      <button class="btn btn-primary" id="send-review" type="submit">Send review</button>
      <p class="review-status" id="review-status" role="status" aria-live="polite"></p>
      <a class="btn btn-secondary review-email-link" id="send-review-email" hidden>Open email app to send review</a>
    </form>
  </dialog>
  <script src="js/config.js"></script>
  <script>
    document.getElementById('unlock-book').addEventListener('click', function () {
      document.getElementById('reader-gate').hidden = true;
      var manuscript = document.querySelector('.manuscript');
      manuscript.hidden = false;
      document.querySelector('.reader-footer').hidden = false;
      manuscript.focus();
    });
    var reviewDialog = document.getElementById('review-dialog');
    var reviewForm = document.getElementById('review-form');
    document.getElementById('open-review').addEventListener('click', function () { reviewDialog.showModal(); });
    document.getElementById('close-review').addEventListener('click', function () { reviewDialog.close(); });
    reviewDialog.addEventListener('click', function (event) {
      if (event.target === reviewDialog) reviewDialog.close();
    });
    reviewForm.addEventListener('submit', function (event) {
      event.preventDefault();
      if (!reviewForm.reportValidity()) return;
      var fields = new FormData(reviewForm);
      var data = {
        name: fields.get('name').trim(),
        email: fields.get('email').trim(),
        review: fields.get('review').trim(),
        _subject: 'Review of The Women - ' + fields.get('name').trim()
      };
      var emailLink = document.getElementById('send-review-email');
      var reviewStatus = document.getElementById('review-status');
      var sendButton = document.getElementById('send-review');
      function prepareEmail(message) {
        var subject = encodeURIComponent(data._subject);
        var body = encodeURIComponent('Name: ' + data.name + '\\nEmail: ' + data.email + '\\n\\nReview:\\n' + data.review);
        emailLink.href = 'mailto:' + ((window.SITE_CONFIG || {}).email || 'mmonibah3@gmail.com') + '?subject=' + subject + '&body=' + body;
        emailLink.hidden = false;
        reviewStatus.textContent = message;
        emailLink.focus();
      }
      if (!(window.SITE_CONFIG || {}).formEndpoint) {
        prepareEmail('Your email app will open. Press Send there to deliver your review.');
        return;
      }
      sendButton.disabled = true;
      reviewStatus.textContent = 'Sending your review...';
      fetch(window.SITE_CONFIG.formEndpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
        body: JSON.stringify(data)
      }).then(function (response) {
        if (!response.ok) throw new Error('Review service rejected the submission.');
        reviewForm.reset();
        reviewStatus.textContent = 'Thank you. Your review was sent.';
      }).catch(function () {
        prepareEmail('The email service did not accept this review. Open your email app and press Send to deliver it.');
      }).then(function () {
        sendButton.disabled = false;
      });
    });
  </script>
</body>
</html>
'@
  $html = $html.Replace('__MANUSCRIPT__', $body.ToString())
  $destination = [System.IO.Path]::GetFullPath($OutputPath)
  [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($destination)) | Out-Null
  [System.IO.File]::WriteAllText($destination, $html, [System.Text.UTF8Encoding]::new($false))
  Write-Output "Wrote $destination"
}
finally {
  $archive.Dispose()
}