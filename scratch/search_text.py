import os

search_terms = ["South Africa", "Czechia", "South Korea", "Bosnia"]
found = False

for root, dirs, files in os.walk("C:\\Users\\alima\\Music\\fifa2026_app"):
    # Skip build and hidden directories
    if ".dart_tool" in root or "build" in root or ".git" in root:
        continue
    for file in files:
        if file.endswith(".dart") or file.endswith(".yaml") or file.endswith(".json"):
            path = os.path.join(root, file)
            try:
                with open(path, "r", encoding="utf-8") as f:
                    content = f.read()
                    for term in search_terms:
                        if term in content:
                            print(f"Found '{term}' in {path}")
                            found = True
            except Exception as e:
                pass

if not found:
    print("None of the search terms found in fifa2026_app files.")
