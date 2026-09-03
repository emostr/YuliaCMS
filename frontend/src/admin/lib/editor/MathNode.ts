import { Node, mergeAttributes } from '@tiptap/core';
import katex from 'katex';

// An inline formula inside rich text.
//
// The LaTeX source is what gets stored; KaTeX renders it for display. Keeping
// the source means the same formula can be re-rendered anywhere - in the
// editor, on the published page - without a screenshot of it ever existing.
//
// The node is an atom: the cursor treats a formula as one character, so
// arrowing past it never lands inside half a fraction.

declare module '@tiptap/core' {
  interface Commands<ReturnType> {
    formula: {
      insertFormula: (latex: string) => ReturnType;
      updateFormula: (latex: string) => ReturnType;
    };
  }
}

function render(latex: string): string {
  if (!latex.trim()) return '';

  try {
    return katex.renderToString(latex, { throwOnError: false, output: 'html' });
  } catch {
    // A formula that will not parse still has to be visible, otherwise it
    // cannot be selected and fixed.
    return latex;
  }
}

export const MathInline = Node.create({
  name: 'formula',
  group: 'inline',
  inline: true,
  atom: true,
  selectable: true,

  addAttributes() {
    return {
      latex: {
        default: '',
        parseHTML: (element) => element.getAttribute('data-latex') ?? '',
        renderHTML: (attributes) => ({ 'data-latex': attributes.latex })
      }
    };
  },

  parseHTML() {
    return [{ tag: 'span[data-latex]' }];
  },

  renderHTML({ HTMLAttributes, node }) {
    const latex = String(node.attrs.latex ?? '');
    return [
      'span',
      mergeAttributes(HTMLAttributes, {
        class: `ng-formula${latex.trim() ? '' : ' is-empty'}`,
        'data-type': 'formula'
      })
    ];
  },

  // The DOM the editor shows is not the DOM that gets stored: on screen the
  // formula is rendered maths, in the document it stays a data-latex span.
  addNodeView() {
    return ({ node }) => {
      const dom = document.createElement('span');
      const latex = String(node.attrs.latex ?? '');

      dom.className = `ng-formula${latex.trim() ? '' : ' is-empty'}`;
      dom.setAttribute('data-type', 'formula');
      dom.setAttribute('data-latex', latex);
      dom.innerHTML = render(latex);

      return { dom };
    };
  },

  addCommands() {
    return {
      insertFormula:
        (latex: string) =>
        ({ commands }) =>
          commands.insertContent({ type: this.name, attrs: { latex } }),

      updateFormula:
        (latex: string) =>
        ({ commands }) =>
          commands.updateAttributes(this.name, { latex })
    };
  }
});
