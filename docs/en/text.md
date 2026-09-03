---
title: Text and formulas
description: Yulia's rich text editor, including LaTeX inline in the text.
permalink: /en/text/
---

The Text block is a proper editor rather than a typing box. What you see in it is what lands on the page.

## Formatting

The toolbar above the field: bold, italic, subheading, bulleted and numbered lists, quote, monospaced code.

The usual keyboard shortcuts work too — <kbd>Ctrl</kbd>+<kbd>B</kbd>, <kbd>Ctrl</kbd>+<kbd>I</kbd>.

The rightmost button strips all formatting from the selection. It earns its place when text has been pasted from Word and brought somebody else's fonts with it.

## What is kept and what is not

The editor is deliberately narrow. Kept: paragraphs, bold, italic, subheadings, lists, quotes, code, links, pictures and formulas.

Not kept: text colour, font size, alignment within a paragraph. This is not an oversight. Appearance belongs to the site, not to an individual paragraph — otherwise a page turns into a patchwork within six months, and changing the site's look becomes impossible.

## Formulas

The **Σ** button inserts a formula. The syntax is LaTeX, the same as in textbooks and papers.

The formula dialog is arranged with the input and a live preview on the left, and ready-made fragments on the right.

### Ready-made fragments

More than a hundred of them, grouped the way a textbook would group them: fractions and powers, operations and comparisons, algebra, geometry and trigonometry, calculus, sets and logic, physics and chemistry, Greek letters.

There is a search box: type "fraction" or "root" and the list narrows.

A fragment is inserted **where the caret is**, not appended. That matters: it is what lets you add an exponent inside a fraction you have already started.

### Examples

| What you want | LaTeX |
|---|---|
| fraction | `\frac{1}{2}` |
| power | `x^{2}` |
| square root | `\sqrt{x}` |
| sum | `\sum_{i=1}^{n} i` |
| integral | `\int_{0}^{1} x\,dx` |
| Greek letter | `\alpha` |

### How a formula is stored

The database holds **the LaTeX source**, not an image. So a formula:

- looks the same in the editor and on the published page;
- can be edited at any time — click it and press **Σ**;
- stays sharp when magnified, and can be read by a screen reader.

Rendering is done by [KaTeX](https://katex.org).

### When a formula will not render

The preview shows the error immediately. It is usually braces: `\frac{1}{2}` is right, `\frac{1}{2` is not.

Yulia saves a broken formula anyway and shows it as-is, so that it can be selected and fixed rather than hunted for.

## Pictures inside text

Prefer the Image block: it has a caption and a width setting. A picture inside the text block only makes sense when it belongs mid-paragraph.

## Pasting from another editor

Text from Word, Google Docs or a web page pastes cleanly: Yulia keeps the structure — paragraphs, lists, bold — and discards the foreign styling.

If something still arrives wrong, select it and press the clear-formatting button.
