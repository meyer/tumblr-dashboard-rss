export const ucfirst = (potentialString: string) => {
  const s = `${potentialString}`;
  return `${s.charAt(0).toUpperCase()}${s.slice(1)}`;
};

export const howmany = (count: number, singular: string, plural?: string) => {
  return `${count} ${count === 1 ? singular : plural || `${singular}s`}`;
};

export const img = (
  src: string,
  width: number,
  height: number,
  opts: Record<string, string> = {}
) => {
  opts.src = src;
  opts.width = width + '';
  opts.height = height + '';
  return `<img ${Object.keys(opts)
    .map((k) => (opts[k] ? `${k}=\"${opts[k]}\"` : ''))
    .join(' ')}>`;
};

export const getTimeDiffString = (t: number, p: string) => {
  let timeInt = Math.abs(t);
  const pfx = p ? ` ${p}` : '';

  if (t <= 1000) {
    return '';
  }

  if ((timeInt /= 1000) < 60)
    return `${Math.round(timeInt * 10) / 10} seconds${pfx}`;
  if ((timeInt /= 60) < 60)
    return `${Math.round(timeInt * 10) / 10} minutes${pfx}`;
  if ((timeInt /= 60) < 24)
    return `${Math.round(timeInt * 10) / 10} hours${pfx}`;
  if ((timeInt /= 24) < 7) return `${Math.round(timeInt * 10) / 10} days${pfx}`;

  return `${Math.round((t / 7) * 10) / 10} weeks${pfx}`;
};

// look at me, parsing HTML with regular expressions
export const wrapHTMLMaybe = (text: string, tag: string) => {
  const trimmedText = `${text}`.trim();
  const rStart = /^\<(\w+)\>/;
  const openingTag = trimmedText.match(rStart);

  if (openingTag && openingTag[1] === tag) {
    return trimmedText;
  }
  return `<${tag}>\n\n${trimmedText}\n\n</${tag}>`;
};
