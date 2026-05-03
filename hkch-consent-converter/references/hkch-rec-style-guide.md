# HKCH REC Document Style Guide

Formatting specifications extracted from the official HKCH REC template.

## Page Layout

- **Page size**: A4 (11906 × 16838 twips)
- **Margins**: top=992, right=849, bottom=992, left=992, header=851, footer=715 (twips)
- 1 twip = 1/1440 inch. These equate roughly to: top/bottom ~1.75cm, left ~1.75cm, right ~1.5cm

## Typography

### Fonts
- **English text**: Arial (font_ascii, font_hAnsi)
- **Chinese text**: PMingLiU (font_eastAsia) — traditional Chinese serif
- **Default body size**: ~11pt (size=22 in half-points). The HKCH reference does NOT set explicit sizes on most runs — it relies on the Normal style default

### Section Headings
- **Bold only** — NO underline (unlike the source electrosclerotherapy doc which uses bold+underline)
- Same font size as body text (no enlarged headings)
- Same paragraph formatting as body (alignment=both)
- Examples: `研究簡介`, `研究目的`, `研究程序`, `Invitation`, `Introduction`, `Purpose of the Study`

### Title / Document Headers
- **Center aligned** (`alignment=center`)
- **Bold**
- Study title uses `研究題目:` / `Study Title:` prefix, bold throughout

## Paragraph Formatting

- **Body text**: `alignment=both` (fully justified)
- **Between sections**: empty paragraph as separator (no spacing_before/after attributes — just blank `<w:p>`)
- **No borders** on paragraphs (unlike source doc which uses `has_border`)
- **No explicit spacing_before/after** — relies on style defaults

## Lists

- Style: `List Paragraph`
- Numbering: `LIST(level=0, numId=N)` — numbered lists (not bullet points)
- Used for authorization items under the privacy/confidentiality section
- Alignment: `both` (justified)

## Signature Tables

### Structure
- Uses `<w:tbl>` (Word table) with `Table Grid` style
- Rows alternate between: empty spacer rows and label rows
- **Chinese consent table** has 10 rows covering:
  - 參加者姓名 / 簽署 (12-18歲或以上) / 日期
  - 父母/法定監護人姓名 (註明與參加者之關係) / 簽署 / 日期
  - 研究人員姓名 / 簽署 / 日期
  - 簽署同意書人士的姓名 (如與研究人員不同) / 簽署 / 日期
  - 見證人姓名（如適用）/ 簽署 / 日期
- **English consent table** splits into two tables:
  - Table 1 (6 rows): Participant / Parent/Guardian / Research Investigator
  - Table 2 (4 rows): Person taking consent / Witness

## Document Sections Order (Styles Used)

The HKCH reference uses almost exclusively the `Normal` style for body text. It does NOT use Heading1-9 styles. Section headings are simply bold paragraphs in Normal style.

No special styles are used for section headings — they are differentiated by **bold formatting only** at the run level.
