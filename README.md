# BOOKies — Official Author Website

Plain HTML, CSS and JavaScript. No build step, no dependencies. Open `index.html` to preview, or upload the whole folder to any static host (Netlify, GitHub Pages, Vercel, Cloudflare Pages, or normal web hosting).

## What to edit (all in `js/config.js`)
| Setting | What it does |
|---|---|
| `instagramUrl` | Your Instagram link (used in every Instagram button) |
| `email` | Your email shown in Contact |
| `bookCover` | File name of your cover image |
| `formEndpoint` | Form service URL used to email contact messages and reader reviews |
| `siteName` | Website brand shown in the header and footer |
| `authorName`, `bookTitle`, `genre` | Author and book details |

## Book cover
The site uses the custom 2:3 vector cover at `assets/the-women-cover.svg`, configured through `bookCover` in `js/config.js`. Replace the file or update that setting to use a different cover.

## Send contact messages and reviews by email
1. Create a free form at https://formspree.io (or a similar form service).
2. Copy the form URL, e.g. `https://formspree.io/f/xxxxxxx`.
3. Paste it into `formEndpoint` in `js/config.js`. The same verified endpoint is used for contact messages and book reviews.

Until you configure and verify an endpoint, the contact and review forms open the visitor's email app with a prepared message. The visitor must press Send there; a static website cannot send email directly.

## Note on hard-coded placeholders
The website has fallback contact details in `index.html` for visitors with JavaScript disabled. Update those fallbacks along with `js/config.js` if contact details change.

## Full book reader
The complete manuscript is published in `book.html`. The reader first asks visitors to follow [Monibah on Instagram](https://instagram.com/mrtvilo._), then select the confirmation button to reveal the book. This is an honor-based prompt because the static site cannot verify Instagram follows. After reading, the review popup sends via `formEndpoint` when configured, or prepares an email to `mmonibah3@gmail.com` as a fallback. To regenerate the reader after updating the source DOCX, run `powershell -ExecutionPolicy Bypass -File tools/convert-manuscript.ps1 -InputPath "D:\The_Women.docx"`.

## Content source
The book description, themes, dedication, content note, excerpt, and full reader are based on the supplied manuscript. No reviews, awards or publisher are claimed.
