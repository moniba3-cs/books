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
  <title>The Women: Read the Full Book</title>
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
    <a class="btn btn-small btn-secondary" href="index.html#read">Back to the website</a>
    <h1>The Women</h1>
    <p class="reader-author">Monibah Mehmood</p>
  </header>
  <main class="reader-main">
    <article class="manuscript" aria-label="The full text of The Women">
__MANUSCRIPT__
    </article>
    <nav class="reader-footer" aria-label="Reader links">
      <a class="btn btn-secondary" href="index.html#community">Follow on Instagram</a>
      <a class="btn btn-primary" href="mailto:mmonibah3@gmail.com?subject=Review%20of%20The%20Women">Write a review</a>
    </nav>
  </main>
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