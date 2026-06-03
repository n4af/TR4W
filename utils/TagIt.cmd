:: TagIt.cmd  — shim so existing usage (utils\TagIt.cmd 4.147.26) is unchanged.
:: Real work lives in TagIt.ps1: sync to origin/master, verify the tag matches
:: Version.pas (same guard as CI), then create and push the tag.
@echo off
powershell -ExecutionPolicy Bypass -File "%~dp0TagIt.ps1" -Tag %1
