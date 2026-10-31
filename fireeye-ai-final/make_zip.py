
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED

root = Path(__file__).resolve().parent
output = root.parent / "fireeye-ai-final.zip"

with ZipFile(output, "w", ZIP_DEFLATED) as archive:

    for folder in ["data", "models"]:
        for file in (root / folder).rglob("*"):
            if file.is_file():
                archive.write(
                    file,
                    file.relative_to(root).as_posix()
                )

    for file in root.glob("*.py"):
        archive.write(file, file.name)

    archive.write(
        root / "requirements.txt",
        "requirements.txt"
    )

print("Final ZIP created:", output)
