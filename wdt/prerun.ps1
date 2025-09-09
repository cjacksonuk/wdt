<#
Adding this following code to trust expired certificates on websites
namely https://onegetcdn.azureedge.net/providers/ which expires every 3months and by chance stopped a enrolment working.
See also https://patchmypc.com/blog/no-match-was-found-while-installing-the-nuget-packageprovider/
#>
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

add-type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
        return true;
    }
}
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

