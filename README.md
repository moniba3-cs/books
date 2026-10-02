# The Women — Official Author Website

Plain HTML, CSS and JavaScript. No build step, no dependencies. Open `index.html` to preview, or upload the whole folder to any static host (Netlify, GitHub Pages, Vercel, Cloudflare Pages, or normal web hosting).

## What to edit (all in `js/config.js`)
| Setting | What it does |
|---|---|
| `instagramUrl` | Your Instagram link (used in every Instagram button) |
| `email` | Your email shown in Contact |
| `bookCover` | File name of your cover image |
| `reviewUrl` | Link used by the reader review button |
| `formEndpoint` | Contact form service URL |
| `authorName`, `bookTitle`, `genre` | Names shown across the site |

## Book cover
The site uses the custom 2:3 vector cover at `assets/the-women-cover.svg`, configured through `bookCover` in `js/config.js`. Replace the file or update that setting to use a different cover. The full manuscript stays outside the public site until a verified payment flow can protect delivery.

## Make the contact form send messages
1. Create a free form at https://formspree.io (or a similar form service).
2. Copy the form URL, e.g. `https://formspree.io/f/xxxxxxx`.
3. Paste it into `formEndpoint` in `js/config.js`.

Until you do, the form validates but is honest that nothing was sent. If you only set a real `email`, the form opens the visitor's email app instead.

## Note on hard-coded placeholders
The same placeholder links also appear in `index.html` as defaults (so the site works even if JavaScript is off). Changing `config.js` is enough; to be thorough you can also search `index.html` for `YOUR_USERNAME` and `YOUR_EMAIL`.

## Full book reader
The complete manuscript is published as a web reader in `book.html`. Readers are asked to follow Instagram and confirm before the text is revealed; this is an honor-based prompt because Instagram does not let this static site verify follows. A review button opens an email to the author. To regenerate the reader after updating the source DOCX, run `powershell -ExecutionPolicy Bypass -File tools/convert-manuscript.ps1 -InputPath "D:\The_Women.docx"`.

## Content source
The book description, themes, dedication, content note, excerpt, and full reader are based on the supplied manuscript. No reviews, awards or publisher are claimed.
