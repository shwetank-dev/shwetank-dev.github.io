export const formatDate = (d: Date): string =>
  d.toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' });
