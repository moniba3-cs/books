# The Women — Official Author Website

Plain HTML, CSS and JavaScript. No build step, no dependencies. Open `index.html` to preview, or upload the whole folder to any static host (Netlify, GitHub Pages, Vercel, Cloudflare Pages, or normal web hosting).

## What to edit (all in `js/config.js`)
| Setting | What it does |
|---|---|
| `instagramUrl` | Your Instagram link (used in every Instagram button) |
| `email` | Your email shown in Contact |
| `purchaseLinks` | Amazon, Kobo, Google Play Books, Apple Books URLs |
| `bookCover` | File name of your cover image |
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

## EasyPaisa payments and PDF delivery
The Buy section currently shows an EasyPaisa placeholder for PKR 200; it does not accept payments or deliver the PDF yet. A personal phone number by itself cannot securely confirm a payment or trigger delivery. To enable this, set up an official EasyPaisa merchant/hosted checkout and a server-side payment confirmation flow, then deliver the PDF through an access-controlled link only after payment is verified. Keep the payment credentials and PDF out of public client-side files.

## Content source
Book description, themes, dedication, content note and the Chapter One excerpt come from your manuscript or your supplied copy. No reviews, awards or publisher are claimed.
