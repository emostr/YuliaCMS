// Shapes shared by the editor's pieces.
//
// They live here rather than inside a component because a .svelte instance
// script cannot export types, and because the block list, the picker and the
// properties panel all need to agree on them.

export interface FieldSpec {
  key: string;
  label?: string;
  type: string;
  default?: unknown;
  options?: string[];
  item_fields?: FieldSpec[];
}

export interface BlockDefinition {
  key: string;
  name?: string;
  icon: string;
  category: string;
  builtin: boolean;
  usable: boolean;
  kind?: string;
  build_status?: string;
  description?: string;
  fields: FieldSpec[];
  defaults: Record<string, unknown>;
}

// One block as it sits in a page's document.
export interface Block {
  id: string;
  type: string;
  props: Record<string, unknown>;
}
