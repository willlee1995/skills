---
name: hkch-consent-converter
description: "Convert medical informed consent documents to Hong Kong Children's Hospital (HKCH) Research Ethics Committee (REC) format. Use when converting clinical treatment consent forms, research consent documents, or any medical consent to the official HKCH REC bilingual (Chinese/English) Information Sheet and Informed Consent Form format. Triggers on: HKCH consent conversion, REC format conversion, research ethics consent formatting, HKCH styled consent."
---

# HKCH REC Consent Document Converter

Convert source medical informed consent documents into HKCH REC-styled bilingual Information Sheet and Informed Consent Forms.

## Key Principles

1. **Bilingual structure**: Output must have Chinese first, then English, for both the Information Sheet and Consent Form (4 parts totanjhbl)
2. **Preserve medical accuracy**: Source clinical content must be accurately mapped — never fabricate medical details
3. **Use standard boilerplate**: Many HKCH REC sections have standard wording (privacy, voluntary participation, etc.) — use these exactly
4. **HKCH formatting only**: Bold-only headings (no underline), justified body text, Arial/PMingLiU fonts, Normal style throughout

## References

- **Formatting specs**: Read [hkch-rec-style-guide.md](references/hkch-rec-style-guide.md) for page layout, fonts, paragraph formatting, and signature table structure
- **Template structure**: Read [hkch-rec-template.md](references/hkch-rec-template.md) for exact section ordering, standard boilerplate text in both languages, and consent form statements

**Always read both reference files before starting a conversion.**

## Conversion Workflow

### Step 1: Extract Source Content

Read the source consent document to extract all medical/clinical content. Identify:
- Treatment/procedure name (Chinese and English)
- Mechanism of action / background
- Treatment procedure details
- Benefits
- Risks and side effects
- Alternative treatments
- Any study-specific details (PI, co-investigators, sponsor, duration, sample size)

### Step 2: Map Content to HKCH Sections

Map extracted content to the HKCH REC template sections. Key mapping rules:

| Source Content | HKCH Section |
|---|---|
| Treatment title | 研究題目 / Study Title |
| Background/mechanism | 研究簡介 / Introduction |
| Purpose/objectives | 研究目的 / Purpose of the Study |
| Procedure details | 研究程序 / Study Procedures |
| Benefits | 預期的好處 / Expected Benefit |
| Risks/side effects | 潛在的風險 / Potential Risks |
| Alternatives | 其他程序/治療 / Alternatives |
| Informed consent checkboxes | Consent Form statements |

**Critical adaptation rules:**
- Source documents may use `您` (you) — HKCH REC uses `您/您的孩子` (you/your child) pattern throughout the Information Sheet
- Source documents may have treatment-focused consent — rewrite as research participation consent
- Do NOT copy content from other studies for sections that should contain study-specific information (introduction, procedures, benefits, risks)
- For sections with standard boilerplate (voluntary participation, confidentiality, privacy ordinance, compensation, termination, new information), use the exact text from the template reference

### Step 3: Collect Missing Information

Prompt user for any information not available in the source document:
- Principal Investigator name (Chinese + English), title, department
- Co-investigators (if any)
- Sponsor
- Expected study duration
- Sample size
- Contact phone number
- Any study-specific costs/sponsorship details

### Step 4: Generate Output Document

Use the `docx` skill to create the output .docx file. Follow the docx skill's "Creating a new Word document" workflow using docx-js.

**Formatting requirements** (from style guide):
- Page: A4, margins top=992, right=849, bottom=992, left=992 twips
- Body: Arial (English) / PMingLiU (Chinese), justified, Normal style
- Section headings: Bold only (no underline, no size change)
- Title lines: Center-aligned, bold
- Lists: Numbered (not bullet), for authorization items only
- Signature tables: Use Table Grid style with alternating spacer/label rows
- Empty paragraph between sections as separator
- No paragraph borders

### Step 5: Verify Output

After generating the document, verify:
1. All 4 parts present (CN info sheet, EN info sheet, CN consent, EN consent)
2. Study-specific content accurately preserved from source
3. Standard boilerplate sections match template exactly
4. Formatting matches HKCH style (bold headings, justified text, correct fonts)
5. Signature tables have all required rows
6. No content from other studies leaked in

## Common Mistakes to Avoid

- **DO NOT** use bold+underline for headings (source document style) — HKCH uses bold-only
- **DO NOT** copy "Expected Benefit" or "Risks" text from the ITC reference template — these must come from the actual source document being converted
- **DO NOT** use Calibri font — HKCH uses Arial for English text
- **DO NOT** omit the PI/co-investigator listing at the top of the Information Sheet
- **DO NOT** skip the Privacy Ordinance (Cap. 486) paragraph — it is required
- **DO NOT** use Heading1-9 styles — HKCH uses Normal style with bold runs for headings
