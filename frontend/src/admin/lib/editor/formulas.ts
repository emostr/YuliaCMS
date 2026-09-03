// Ready-made LaTeX fragments, grouped the way a textbook would group them.
//
// Typing LaTeX from memory is a skill; picking "дробь" off a list is not. The
// snippet is inserted at the cursor, so it can be dropped inside something the
// author has already started.

export interface Snippet {
  label: string;
  latex: string;
}

export interface Group {
  title: string;
  items: Snippet[];
}

export const FORMULA_GROUPS: Group[] = [
  {
    title: 'Дроби и степени',
    items: [
      { label: 'дробь', latex: '\\frac{a}{b}' },
      { label: 'степень', latex: 'a^{n}' },
      { label: 'индекс', latex: 'a_{n}' },
      { label: 'корень', latex: '\\sqrt{x}' },
      { label: 'корень n-й', latex: '\\sqrt[n]{x}' },
      { label: 'модуль', latex: '\\left| x \\right|' }
    ]
  },
  {
    title: 'Действия и сравнения',
    items: [
      { label: 'умножение', latex: '\\cdot' },
      { label: 'деление', latex: '\\div' },
      { label: 'плюс-минус', latex: '\\pm' },
      { label: 'не равно', latex: '\\neq' },
      { label: 'меньше либо равно', latex: '\\leq' },
      { label: 'больше либо равно', latex: '\\geq' },
      { label: 'приблизительно', latex: '\\approx' },
      { label: 'бесконечность', latex: '\\infty' }
    ]
  },
  {
    title: 'Алгебра',
    items: [
      { label: 'сумма', latex: '\\sum_{i=1}^{n}' },
      { label: 'произведение', latex: '\\prod_{i=1}^{n}' },
      { label: 'система', latex: '\\begin{cases} a \\\\ b \\end{cases}' },
      { label: 'матрица', latex: '\\begin{pmatrix} a & b \\\\ c & d \\end{pmatrix}' },
      { label: 'логарифм', latex: '\\log_{a} b' },
      { label: 'экспонента', latex: 'e^{x}' }
    ]
  },
  {
    title: 'Геометрия и тригонометрия',
    items: [
      { label: 'угол', latex: '\\angle' },
      { label: 'градус', latex: '^{\\circ}' },
      { label: 'параллельно', latex: '\\parallel' },
      { label: 'перпендикулярно', latex: '\\perp' },
      { label: 'треугольник', latex: '\\triangle' },
      { label: 'синус', latex: '\\sin' },
      { label: 'косинус', latex: '\\cos' },
      { label: 'тангенс', latex: '\\tan' }
    ]
  },
  {
    title: 'Начала анализа',
    items: [
      { label: 'предел', latex: '\\lim_{x \\to 0}' },
      { label: 'интеграл', latex: '\\int_{a}^{b} f(x)\\,dx' },
      { label: 'производная', latex: "f'(x)" },
      { label: 'частная производная', latex: '\\frac{\\partial f}{\\partial x}' }
    ]
  },
  {
    title: 'Множества и логика',
    items: [
      { label: 'принадлежит', latex: '\\in' },
      { label: 'не принадлежит', latex: '\\notin' },
      { label: 'подмножество', latex: '\\subset' },
      { label: 'объединение', latex: '\\cup' },
      { label: 'пересечение', latex: '\\cap' },
      { label: 'пустое множество', latex: '\\varnothing' },
      { label: 'следовательно', latex: '\\Rightarrow' },
      { label: 'равносильно', latex: '\\Leftrightarrow' }
    ]
  },
  {
    title: 'Греческие буквы',
    items: [
      { label: 'альфа', latex: '\\alpha' },
      { label: 'бета', latex: '\\beta' },
      { label: 'гамма', latex: '\\gamma' },
      { label: 'дельта', latex: '\\delta' },
      { label: 'тета', latex: '\\theta' },
      { label: 'лямбда', latex: '\\lambda' },
      { label: 'пи', latex: '\\pi' },
      { label: 'сигма', latex: '\\sigma' },
      { label: 'фи', latex: '\\varphi' },
      { label: 'омега', latex: '\\omega' }
    ]
  },
  {
    title: 'Физика и химия',
    items: [
      { label: 'вектор', latex: '\\vec{v}' },
      { label: 'среднее', latex: '\\overline{x}' },
      { label: 'реакция', latex: '\\rightarrow' },
      { label: 'обратимая реакция', latex: '\\rightleftharpoons' },
      { label: 'дельта величины', latex: '\\Delta' }
    ]
  }
];
