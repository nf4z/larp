Add-Type -AssemblyName System.Drawing

$badgeDirectory = Join-Path $PSScriptRoot 'enchants'
$singleBadges = @(Get-ChildItem -LiteralPath $badgeDirectory -Filter '*.png' |
    Where-Object { $_.BaseName -notlike '* & *' } |
    Sort-Object BaseName)

for ($first = 0; $first -lt $singleBadges.Count; $first++) {
    for ($second = $first + 1; $second -lt $singleBadges.Count; $second++) {
        $name = '{0} & {1}.png' -f $singleBadges[$first].BaseName, $singleBadges[$second].BaseName
        $destination = Join-Path $badgeDirectory $name
        $reverseName = '{0} & {1}.png' -f $singleBadges[$second].BaseName, $singleBadges[$first].BaseName
        if ((Test-Path -LiteralPath $destination) -or
            (Test-Path -LiteralPath (Join-Path $badgeDirectory $reverseName))) { continue }

        $base = [System.Drawing.Image]::FromFile($singleBadges[$first].FullName)
        $front = [System.Drawing.Image]::FromFile($singleBadges[$second].FullName)
        $result = New-Object System.Drawing.Bitmap(256, 256, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $graphics = [System.Drawing.Graphics]::FromImage($result)
        try {
            $graphics.Clear([System.Drawing.Color]::Transparent)
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
            $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            $graphics.DrawImage($base, 0, 0, 178, 178)
            $graphics.DrawImage($front, 78, 78, 178, 178)
            $result.Save($destination, [System.Drawing.Imaging.ImageFormat]::Png)
        }
        finally {
            $graphics.Dispose()
            $result.Dispose()
            $front.Dispose()
            $base.Dispose()
        }
    }
}
