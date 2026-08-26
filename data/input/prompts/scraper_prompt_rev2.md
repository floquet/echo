Objective: Extract information from the provided document based on the "Extraction Schema" defined below.

Extraction Schema:
You must ONLY return a JSON object with the following keys and data types:
- `date`: String (ISO 8601 format: `YYYY-MM-DD`). If no date is found, return `null`.
- `owner`: String. Must be selected strictly from the "Approved Product List". If no match is found, return `null`.
- `gov_personnel`: Array of Objects. Each object contains `{"name": "string", "role": "string"}`.
- `ctr_personnel`: Array of Objects. Each object contains `{"name": "string", "role": "string"}`.
- `leadership_messages`: Object containing keys `{"message1": "string", "message2": "string", "message3": "string"}`.
- `score_overall`: Integer. Must be exactly `-1`, `0`, or `1`.
- `rationale`: String.
- `areas`: Array of Objects. Each object contains `{"area_name": "string", "score": integer (-1, 0, or 1), "text": "string"}`. The area_name must be selected exactly from the "Fixed Assessment Areas List".
- `products`: String.
- `strengths`: String.
- `concerns`: String.
- `questions`: String.
- `integration`: String.

Approved Product List:
- Choose an item.
- Flight Systems Segment
- Boosters Branch - NIXB
- Post-Boot Branch - NIXA
- Guidance & Navigation Branch - NIXG
- Reentry Systems Branch - NIXV
- Support Equipment Branch - NIXU
- Command Systems Segment
- Launch Silos Branch - NIXX
- Secondary Launch Capabilities Branch - NIXC
- Wing Operations Branch - NIXC
- Launch Systems Segment
- Launch Silos Branch - NIXH
- Launch Centers Branch - NIXD
- Wing Comm Infrastructure Branch - NIXI
- Traditional Mil Construction Branch - NIXJ
- Deployment Branch - NIXK
- System Integration Segment
- Product Support Branch - NIXR
- Mission Threads Branch - NIXM
- Enterprise Software Branch - NIXY
- Mission Assurance Branch - NIXN
- Training Systems Branch - NIXZ
- Sentinel UMD Functions
- Sentinel Engineering - NIXE
- Sentinel Financial Mgmt - NIXM
- Sentinel Logistics - NIXL
- Sentinel Program Mgmt - NIXP
- Sentinel Security - NIXS
- Sentinel Test & Evaluation - NIXT
- Sentinel Software - NIXW
- Sentinel Program Office - NIX
- Division Operations Branch - NIXO
- Acquisition Integration Branch - NIXQ

Fixed Assessment Areas:
- Scope and Deliverables Definition
- Schedule Planning and IMS-Loading Readiness
- Cross-Product/Cross-Function Integration

Strict Formatting Rules:
- No Conversational Filler: Return ONLY the JSON object. No introductory or concluding text.
- Data Types:
  - Integers (scores) must NOT be wrapped in quotes (e.g., 1, not "1").
    Missing values must be null (no quotes).
- JSON Validity: Ensure the output is valid JSON. Use double quotes for all keys and string values.
- Personnel Extraction: Split participants into name and role.
  - Example: "Ron Sterling (ML)" → {"name": "Ron Sterling", "role": "ML"}.
- Accuracy: Do not hallucinate. If a field is not present in the document, set it to null.
- Do not summarize, truncate, or paraphrase. Copy all text from the rationale, strengths, concerns, and integration boxes exactly as written.

Execution Process:
1. Scan: Locate the specific fields defined in the schema.
2. Product Match: Cross-reference mentioned products against the "Approved Product List".
3. Score Mapping: Identify the checked box (marked with an "X") for the Overall Rating and each Fixed Assessment Area. Map as follows:
   - Strong → 1
   - Moderate → 0
   - Low → -1
4. Construct: Build the JSON object according to the schema.on the checkboxes mentioned in the text. Construct the JSON object according to the schema.
