. .\verify_integrity.ps1

$filePath = ".\..\file_integrity_scanner_app\local_be\File-Integrity-Scanner-1.7.jar"
$expectedSha256 = "489E5D3F0CBAECA0D356B19444A3DAAA67625ADCAEBA3828F6D1658A6B980CC6"

if (Verify-SHA256 -FilePath $filePath -ExpectedHash $expectedSha256) {
    Write-Host "The file hash matches the expected SHA256."
} else {
    Write-Host "The file hash does NOT match the expected SHA256."
}