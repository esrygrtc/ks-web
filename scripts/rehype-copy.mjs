// Build-time copy buttons: every fenced code block in markdown content
// gets its button in the static HTML, so the gate can count them and a
// no-JS reader still sees honest structure. The client script that makes
// them work ships in the docs layout.
export default function rehypeCopy() {
  return (tree) => {
    const visit = (node, cb) => {
      cb(node);
      (node.children ?? []).forEach((c) => visit(c, cb));
    };
    visit(tree, (node) => {
      if (node.type !== 'element' || node.tagName !== 'pre') return;
      if (node.properties?.dataCopyWrapped) return;
      const text = (function collect(n) {
        if (n.type === 'text') return n.value;
        return (n.children ?? []).map(collect).join('');
      })(node);
      node.properties.dataCopyWrapped = 'true';
      node.children.push({
        type: 'element', tagName: 'button',
        properties: { type: 'button', className: ['ks-copy'], 'data-copy': text.trimEnd() },
        children: [{ type: 'text', value: 'copy' }],
      });
    });
  };
}
