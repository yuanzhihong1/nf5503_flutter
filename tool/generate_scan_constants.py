#!/usr/bin/env python3
"""Generate Dart mirrors of the public constants in ScanManager_V*.jar."""

from __future__ import annotations

import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
JARS = sorted((ROOT / "android/libs").glob("ScanManager_V*.jar"))
if not JARS:
    raise SystemExit("ScanManager_V*.jar was not found under android/libs")
JAR = JARS[-1]
OUTPUT = ROOT / "lib/src/nf5503_scan_constants.dart"

CLASSES = [
    ("DecoderConfigValues$EngineID", "Nf5503ScanEngineId", "DecoderConfigValues.EngineID"),
    ("DecoderConfigValues$EngineType", "Nf5503ScanEngineType", "DecoderConfigValues.EngineType"),
    ("DecoderConfigValues$LightsMode", "Nf5503ScanLightsMode", "DecoderConfigValues.LightsMode"),
    ("DecoderConfigValues$OCRMode", "Nf5503ScanOcrMode", "DecoderConfigValues.OCRMode"),
    ("DecoderConfigValues$OCRTemplate", "Nf5503ScanOcrTemplate", "DecoderConfigValues.OCRTemplate"),
    ("DecoderConfigValues$ParamID", "Nf5503ScanParamId", "DecoderConfigValues.ParamID"),
    ("DecoderConfigValues$PostalConfig", "Nf5503ScanPostalConfig", "DecoderConfigValues.PostalConfig"),
    ("DecoderConfigValues$SymbologyFlags", "Nf5503ScanSymbologyFlags", "DecoderConfigValues.SymbologyFlags"),
    ("DecoderConfigValues$SymbologyID", "Nf5503ScanSymbologyId", "DecoderConfigValues.SymbologyID"),
    ("ScannerType", "Nf5503ScannerTypeId", "ScannerType"),
    ("ScanConfig", "Nf5503ScanConfig", "ScanConfig"),
]

FIELD_RE = re.compile(
    r"public static final (?P<type>[^\s]+) (?P<name>[A-Z0-9_]+)"
    r"(?: = (?P<value>.*))?;"
)


def javap(class_name: str) -> str:
    target = f"android.bld.scan.configuration.{class_name}"
    return subprocess.check_output(
        ["javap", "-classpath", str(JAR), "-public", "-constants", target],
        text=True,
    )


def dart_value(java_type: str, value: str | None) -> str:
    if value is None:
        raise RuntimeError(f"Constant has no compile-time value for {java_type}")
    value = value.strip()
    if java_type == "int":
        return value
    if java_type == "java.lang.String":
        decoded = json.loads(value)
        escaped = (
            decoded.replace("\\", "\\\\")
            .replace("'", "\\'")
            .replace("\n", "\\n")
            .replace("\r", "\\r")
            .replace("\t", "\\t")
        )
        return f"'{escaped}'"
    if java_type == "char":
        # javap prints Java char literals. Emit their integer code unit so the
        # value can be reused through the int-based ScanManager API.
        decoded = json.loads(value.replace("'", '"'))
        if len(decoded) != 1:
            raise RuntimeError(f"Unexpected char literal: {value}")
        return f"0x{ord(decoded):04X}"
    raise RuntimeError(f"Unsupported Java constant type: {java_type}")


def main() -> None:
    blocks = [
        "// GENERATED CODE - DO NOT MODIFY BY HAND.",
        "// Run tool/generate_scan_constants.py after updating the vendor SDK jar.",
        "// ignore_for_file: constant_identifier_names",
        "",
        "// NF5503 扫码 SDK 公开常量镜像。",
        "//",
        f"// 所有值和名称均来自 `{JAR.name}`，可直接用于",
        "// `Nf5503Scanner.setParameter`、`Nf5503Scanner.getParameter` 等通用参数 API。",
    ]
    for java_class, dart_class, sdk_name in CLASSES:
        output = javap(java_class)
        fields = []
        for line in output.splitlines():
            match = FIELD_RE.search(line.strip())
            if not match:
                continue
            name = match.group("name")
            java_type = match.group("type")
            value = dart_value(java_type, match.group("value"))
            dart_type = "String" if java_type == "java.lang.String" else "int"
            fields.append((name, dart_type, value))
        if not fields:
            raise RuntimeError(f"No constants found in {java_class}")
        blocks.extend(
            [
                "",
                f"/// 对齐原生 `{sdk_name}`。",
                f"abstract final class {dart_class} {{",
            ]
        )
        for name, dart_type, value in fields:
            blocks.extend(
                [
                    f"  /// 原生常量 `{sdk_name}.{name}`。",
                    f"  static const {dart_type} {name} = {value};",
                ]
            )
        blocks.append("}")
    OUTPUT.write_text("\n".join(blocks) + "\n", encoding="utf-8")
    subprocess.run(["dart", "format", str(OUTPUT)], check=True)
    print(f"Wrote {OUTPUT} ({sum(1 for b in blocks if 'static const' in b)} constants)")


if __name__ == "__main__":
    main()
