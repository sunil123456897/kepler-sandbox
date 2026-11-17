param(
    [int]$TimeoutSec = 30
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$ProjectDir = $PSScriptRoot
$GodotExe = Join-Path (Split-Path $ProjectDir -Parent) "bin\Godot_v4.7.2-stable_win64_console.exe"
if (-not (Test-Path -LiteralPath $GodotExe)) {
    throw "Godot binary not found at: $GodotExe"
}

$ShotsDir = Join-Path $ProjectDir "screenshots"
New-Item -ItemType Directory -Force -Path $ShotsDir | Out-Null
$MacroPath = Join-Path $ShotsDir "world_macro.png"
$ZoomPath = Join-Path $ShotsDir "world_zoom.png"
$CivShotPath = Join-Path $ShotsDir "stage2_civ.png"
$NightShotPath = Join-Path $ShotsDir "stage2_night.png"
$CombatShotPath = Join-Path $ShotsDir "stage3_war.png"

$ErrorPattern = "(Assertion failed|Parse Error|Compile Error|SCRIPT ERROR|SHADER ERROR|Shader compilation failed)"
$LeakPattern = "(ObjectDB instances leaked|resources still in use at exit|RID allocations|leaked at exit)"

function Stop-StrayGodot {
    $running = @(Get-Process -Name "Godot*" -ErrorAction SilentlyContinue)
    foreach ($p in $running) {
        Write-Warning "Killing stray Godot process: $($p.ProcessName) (PID $($p.Id))"
        & taskkill /PID $p.Id /T /F 2>$null | Out-Null
    }
}

function Assert-NoActiveGodot {
    $running = @(Get-Process -Name "Godot*" -ErrorAction SilentlyContinue)
    if ($running.Count -gt 0) {
        $details = ($running | ForEach-Object { "$($_.ProcessName) (PID $($_.Id))" }) -join ", "
        throw "Refusing to launch Godot while another Godot process is active: $details"
    }
}

function Invoke-GodotGuarded {
    param(
        [string[]]$GodotArgs,
        [string]$Label
    )

    Assert-NoActiveGodot

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $GodotExe
    $psi.Arguments = ($GodotArgs -join " ")
    $psi.WorkingDirectory = $ProjectDir
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
    $psi.StandardErrorEncoding = [System.Text.Encoding]::UTF8

    $proc = [System.Diagnostics.Process]::Start($psi)
    try {
        $stdoutTask = $proc.StandardOutput.ReadToEndAsync()
        $stderrTask = $proc.StandardError.ReadToEndAsync()

        if (-not $proc.WaitForExit($TimeoutSec * 1000)) {
            $procId = $proc.Id
            & taskkill /PID $procId /T /F 2>$null | Out-Null
            try { $proc.WaitForExit(2000) | Out-Null } catch {}
            try { [void]$stdoutTask.Wait(1000) } catch {}
            try { [void]$stderrTask.Wait(1000) } catch {}
            $pOut = if ($stdoutTask.Status -eq "RanToCompletion") { $stdoutTask.Result } else { "" }
            $pErr = if ($stderrTask.Status -eq "RanToCompletion") { $stderrTask.Result } else { "" }
            $partial = ($pOut + "`n" + $pErr).Trim()
            if ($partial.Length -gt 0) {
                Write-Host $partial
            }
            throw "[$Label] Godot timed out after ${TimeoutSec}s (PID $procId killed)."
        }

        [void]$stdoutTask.Wait(3000)
        [void]$stderrTask.Wait(3000)
        $sw.Stop()

        $stdout = if ($stdoutTask.Status -eq "RanToCompletion") { $stdoutTask.Result } else { "" }
        $stderr = if ($stderrTask.Status -eq "RanToCompletion") { $stderrTask.Result } else { "" }
        $combined = ($stdout + "`n" + $stderr).Trim()

        if ($combined.Length -gt 0) {
            Write-Host $combined
        }

        if ($combined -match $LeakPattern) {
            throw "[$Label] Resource, ObjectDB, or RID leak detected in Godot output."
        }
        if ($combined -match $ErrorPattern) {
            throw "[$Label] Godot reported critical error matching $ErrorPattern."
        }
        if ($proc.ExitCode -ne 0) {
            throw "[$Label] Godot exited with code $($proc.ExitCode)."
        }

        Write-Host ("[{0}] Completed in {1} ms (exit=0)" -f $Label, $sw.ElapsedMilliseconds)
        return $combined
    }
    finally {
        try {
            if ($null -ne $proc -and -not $proc.HasExited) {
                & taskkill /PID $proc.Id /T /F 2>$null | Out-Null
            }
        } catch {}
        if ($null -ne $proc) {
            $proc.Dispose()
        }
    }
}

function Assert-ShotValid {
    param(
        [string]$Path,
        [string]$Label,
        [long]$MinBytes = 102400,
        [switch]$CheckColorVariance
    )
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "[$Label] Screenshot was not created at $Path"
    }
    $bytes = (Get-Item -LiteralPath $Path).Length
    if ($bytes -lt $MinBytes) {
        throw "[$Label] Screenshot too small ($bytes bytes < $MinBytes bytes) at $Path"
    }
    if ($CheckColorVariance) {
        Add-Type -AssemblyName System.Drawing
        $bmp = [System.Drawing.Bitmap]::new($Path)
        try {
            if ($bmp.Width -lt 640 -or $bmp.Height -lt 360) {
                throw "[$Label] Screenshot resolution too small ($($bmp.Width)x$($bmp.Height)) at $Path"
            }
            $buckets = New-Object 'System.Collections.Generic.HashSet[int]'
            $minR = 255; $maxR = 0
            $minG = 255; $maxG = 0
            $minB = 255; $maxB = 0
            $cols = 32
            $rows = 18
            for ($gy = 0; $gy -lt $rows; $gy++) {
                $py = [int](($gy + 0.5) * $bmp.Height / $rows)
                for ($gx = 0; $gx -lt $cols; $gx++) {
                    $px = [int](($gx + 0.5) * $bmp.Width / $cols)
                    $c = $bmp.GetPixel($px, $py)
                    if ($c.R -lt $minR) { $minR = $c.R }
                    if ($c.R -gt $maxR) { $maxR = $c.R }
                    if ($c.G -lt $minG) { $minG = $c.G }
                    if ($c.G -gt $maxG) { $maxG = $c.G }
                    if ($c.B -lt $minB) { $minB = $c.B }
                    if ($c.B -gt $maxB) { $maxB = $c.B }
                    $q = (([int]$c.R -shr 4) -shl 8) -bor (([int]$c.G -shr 4) -shl 4) -bor ([int]$c.B -shr 4)
                    [void]$buckets.Add($q)
                }
            }
            $spread = ($maxR - $minR) + ($maxG - $minG) + ($maxB - $minB)
            if ($buckets.Count -lt 12 -or $spread -lt 80) {
                throw "[$Label] Screenshot lacks varied colors (buckets=$($buckets.Count), rgb_spread=$spread) at $Path"
            }
            Write-Host ("[{0}] Image check: {1}x{2}, {3} bytes, color_buckets={4}, rgb_spread={5}" -f $Label, $bmp.Width, $bmp.Height, $bytes, $buckets.Count, $spread)
        }
        finally {
            $bmp.Dispose()
        }
    }
    return $bytes
}

function Parse-StringMetric {
    param(
        [string]$Text,
        [string]$Key,
        [string]$Label
    )
    if ($Text -match "(?:^|\s)$Key=(\S+)") {
        return $Matches[1]
    }
    throw "[$Label] Missing string metric '$Key=' in output."
}

function Parse-IntMetric {
    param(
        [string]$Text,
        [string]$Key,
        [string]$Label
    )
    if ($Text -match "(?:^|\s)$Key=(-?\d+)") {
        return [int]$Matches[1]
    }
    throw "[$Label] Missing integer metric '$Key=' in output."
}

function Parse-NumMetric {
    param(
        [string]$Text,
        [string]$Key,
        [string]$Label
    )
    if ($Text -match "(?:^|\s)$Key=(-?\d+(?:\.\d+)?)") {
        return [double]::Parse($Matches[1], [System.Globalization.CultureInfo]::InvariantCulture)
    }
    throw "[$Label] Missing numeric metric '$Key=' in output."
}

Assert-NoActiveGodot

try {
    Write-Host "=== Step 1: Stage 2.5 Headless Smoke Regression ==="
    $smokeSw = [System.Diagnostics.Stopwatch]::StartNew()
    $smokeOut = Invoke-GodotGuarded -GodotArgs @("--headless", "--path", "`"$ProjectDir`"", "--", "--smoke") -Label "SMOKE"
    $smokeSw.Stop()
    if ($smokeOut -notmatch "SMOKE_PASS") {
        throw "[SMOKE] Expected SMOKE_PASS marker in output."
    }
    $smokeUnits = Parse-IntMetric -Text $smokeOut -Key "units" -Label "SMOKE"
    $smokeFlora = Parse-IntMetric -Text $smokeOut -Key "flora" -Label "SMOKE"
    $smokeMaxSpeed = Parse-NumMetric -Text $smokeOut -Key "max_speed" -Label "SMOKE"
    if ($smokeUnits -lt 100) {
        throw "[SMOKE] Expected units >= 100, got $smokeUnits"
    }
    if ($smokeFlora -lt 400) {
        throw "[SMOKE] Expected flora >= 400, got $smokeFlora"
    }
    if ($smokeMaxSpeed -le 80.0) {
        throw "[SMOKE] Expected max_speed > 80.0, got $smokeMaxSpeed"
    }
    if ($smokeSw.Elapsed.TotalSeconds -ge $TimeoutSec) {
        throw "[SMOKE] Timing budget exceeded: $($smokeSw.Elapsed.TotalSeconds)s"
    }

    Write-Host "=== Step 2: Macro World Screenshot ==="
    if (Test-Path -LiteralPath $MacroPath) { Remove-Item -LiteralPath $MacroPath -Force }
    $null = Invoke-GodotGuarded -GodotArgs @("--path", "`"$ProjectDir`"", "--", "`"--shot-macro=$MacroPath`"") -Label "MACRO_SHOT"
    $macroBytes = Assert-ShotValid -Path $MacroPath -Label "MACRO_SHOT" -MinBytes 153600 -CheckColorVariance

    Write-Host "=== Step 3: Zoom Close-Up Screenshot ==="
    if (Test-Path -LiteralPath $ZoomPath) { Remove-Item -LiteralPath $ZoomPath -Force }
    $null = Invoke-GodotGuarded -GodotArgs @("--path", "`"$ProjectDir`"", "--", "`"--shot-zoom=$ZoomPath`"") -Label "ZOOM_SHOT"
    $zoomBytes = Assert-ShotValid -Path $ZoomPath -Label "ZOOM_SHOT" -MinBytes 102400

    Write-Host "=== Step 4: Stage 3 Civ Headless Smoke & Perf Gates ==="
    $civSw = [System.Diagnostics.Stopwatch]::StartNew()
    $civOut = Invoke-GodotGuarded -GodotArgs @("--headless", "--path", "`"$ProjectDir`"", "--", "--smoke-civ") -Label "SMOKE_CIV"
    $civSw.Stop()
    if ($civOut -notmatch "SMOKE_CIV_PASS") {
        throw "[SMOKE_CIV] Expected SMOKE_CIV_PASS marker in output."
    }
    $cities = Parse-IntMetric -Text $civOut -Key "cities" -Label "SMOKE_CIV"
    $zonesOwned = Parse-IntMetric -Text $civOut -Key "zones_owned" -Label "SMOKE_CIV"
    $buildings = Parse-IntMetric -Text $civOut -Key "buildings" -Label "SMOKE_CIV"
    $techTier = Parse-IntMetric -Text $civOut -Key "tech_tier" -Label "SMOKE_CIV"
    $storageTotal = Parse-NumMetric -Text $civOut -Key "storage_total" -Label "SMOKE_CIV"
    $shuttlesTotal = Parse-IntMetric -Text $civOut -Key "shuttles_total" -Label "SMOKE_CIV"
    $cosmicAge = Parse-StringMetric -Text $civOut -Key "cosmic_age" -Label "SMOKE_CIV"
    $shieldPylons = Parse-IntMetric -Text $civOut -Key "shield_pylons" -Label "SMOKE_CIV"
    $shieldBlocked = Parse-IntMetric -Text $civOut -Key "shield_blocked" -Label "SMOKE_CIV"
    $dodges = Parse-IntMetric -Text $civOut -Key "dodges" -Label "SMOKE_CIV"
    $possessionOk = Parse-IntMetric -Text $civOut -Key "possession_ok" -Label "SMOKE_CIV"
    $worldTickMs = Parse-NumMetric -Text $civOut -Key "world_tick_ms" -Label "SMOKE_CIV"
    $physCivTickMs = Parse-NumMetric -Text $civOut -Key "phys_civ_tick_ms" -Label "SMOKE_CIV"
    $simTickMs = Parse-NumMetric -Text $civOut -Key "sim_tick_ms" -Label "SMOKE_CIV"

    if ($cities -lt 2) { throw "[SMOKE_CIV] Expected cities >= 2, got $cities" }
    if ($zonesOwned -lt 8) { throw "[SMOKE_CIV] Expected zones_owned >= 8, got $zonesOwned" }
    if ($buildings -lt 6) { throw "[SMOKE_CIV] Expected buildings >= 6, got $buildings" }
    if ($techTier -lt 2) { throw "[SMOKE_CIV] Expected tech_tier >= 2, got $techTier" }
    if ($storageTotal -le 0.0) { throw "[SMOKE_CIV] Expected storage_total > 0, got $storageTotal" }
    if ($shuttlesTotal -lt 1) { throw "[SMOKE_CIV] Expected shuttles_total >= 1, got $shuttlesTotal" }
    if ($shieldPylons -lt 1) { throw "[SMOKE_CIV] Expected shield_pylons >= 1, got $shieldPylons" }
    if ($shieldBlocked -lt 1) { throw "[SMOKE_CIV] Expected shield_blocked >= 1, got $shieldBlocked" }
    if ($dodges -lt 1) { throw "[SMOKE_CIV] Expected dodges >= 1, got $dodges" }
    if ($possessionOk -ne 1) { throw "[SMOKE_CIV] Expected possession_ok == 1, got $possessionOk" }
    if ($civSw.Elapsed.TotalSeconds -ge $TimeoutSec) {
        throw "[SMOKE_CIV] Timing budget exceeded: $($civSw.Elapsed.TotalSeconds)s"
    }

    $inv = [System.Globalization.CultureInfo]::InvariantCulture
    $worldTickStr = $worldTickMs.ToString("F3", $inv)
    $physCivTickStr = $physCivTickMs.ToString("F3", $inv)
    $simTickStr = $simTickMs.ToString("F3", $inv)

    if ($worldTickMs -gt 1.20) {
        throw "[SMOKE_CIV] Stop-Kran world timing budget exceeded: world_tick_ms=$worldTickStr ms (> 1.20 ms/tick)"
    }
    if ($physCivTickMs -gt 2.50) {
        throw "[SMOKE_CIV] Stop-Kran phys+civ timing budget exceeded: phys_civ_tick_ms=$physCivTickStr ms (> 2.50 ms/tick)"
    }
    if ($simTickMs -gt 3.80) {
        throw "[SMOKE_CIV] Stop-Kran full sim timing budget exceeded: sim_tick_ms=$simTickStr ms (> 3.80 ms/tick)"
    }

    Write-Host "=== Step 5: Stage 3 Civ Visual Screenshot ==="
    if (Test-Path -LiteralPath $CivShotPath) { Remove-Item -LiteralPath $CivShotPath -Force }
    $null = Invoke-GodotGuarded -GodotArgs @("--path", "`"$ProjectDir`"", "--", "`"--shot-civ=$CivShotPath`"") -Label "CIV_SHOT"
    $civBytes = Assert-ShotValid -Path $CivShotPath -Label "CIV_SHOT" -MinBytes 102400

    Write-Host "=== Step 6: Stage 3 Night/Dusk HDR Screenshot ==="
    if (Test-Path -LiteralPath $NightShotPath) { Remove-Item -LiteralPath $NightShotPath -Force }
    $null = Invoke-GodotGuarded -GodotArgs @("--path", "`"$ProjectDir`"", "--", "`"--shot-night=$NightShotPath`"") -Label "NIGHT_SHOT"
    $nightBytes = Assert-ShotValid -Path $NightShotPath -Label "NIGHT_SHOT" -MinBytes 102400

    Write-Host "=== Step 7: Stage 3B Combat, Diplomacy, Portals & Perf Gates ==="
    $combatSw = [System.Diagnostics.Stopwatch]::StartNew()
    $combatOut = Invoke-GodotGuarded -GodotArgs @("--headless", "--path", "`"$ProjectDir`"", "--", "--smoke-combat") -Label "SMOKE_COMBAT"
    $combatSw.Stop()
    if ($combatOut -notmatch "SMOKE_COMBAT_PASS") {
        throw "[SMOKE_COMBAT] Expected SMOKE_COMBAT_PASS marker in output."
    }
    $beamsFired = Parse-IntMetric -Text $combatOut -Key "beams_fired" -Label "SMOKE_COMBAT"
    $portalTransfers = Parse-IntMetric -Text $combatOut -Key "portal_transfers" -Label "SMOKE_COMBAT"
    $casualties = Parse-IntMetric -Text $combatOut -Key "casualties" -Label "SMOKE_COMBAT"
    $combatTechTier = Parse-IntMetric -Text $combatOut -Key "tech_tier" -Label "SMOKE_COMBAT"
    $warsActive = Parse-IntMetric -Text $combatOut -Key "wars_active" -Label "SMOKE_COMBAT"
    $rebellionsTotal = Parse-IntMetric -Text $combatOut -Key "rebellions_total" -Label "SMOKE_COMBAT"
    $waterStranded = Parse-IntMetric -Text $combatOut -Key "water_stranded" -Label "SMOKE_COMBAT"
    $combatMaxSpeed = Parse-NumMetric -Text $combatOut -Key "max_speed" -Label "SMOKE_COMBAT"
    $combatWorldTickMs = Parse-NumMetric -Text $combatOut -Key "world_tick_ms" -Label "SMOKE_COMBAT"
    $combatPhysCivTickMs = Parse-NumMetric -Text $combatOut -Key "phys_civ_tick_ms" -Label "SMOKE_COMBAT"
    $combatSimTickMs = Parse-NumMetric -Text $combatOut -Key "sim_tick_ms" -Label "SMOKE_COMBAT"
    $combatSaveOk = Parse-IntMetric -Text $combatOut -Key "save_ok" -Label "SMOKE_COMBAT"

    if ($beamsFired -lt 5) { throw "[SMOKE_COMBAT] Expected beams_fired >= 5, got $beamsFired" }
    if ($portalTransfers -lt 4) { throw "[SMOKE_COMBAT] Expected portal_transfers >= 4, got $portalTransfers" }
    if ($casualties -lt 1) { throw "[SMOKE_COMBAT] Expected casualties >= 1, got $casualties" }
    if ($combatTechTier -lt 4) { throw "[SMOKE_COMBAT] Expected tech_tier >= 4, got $combatTechTier" }
    if ($warsActive -lt 1) { throw "[SMOKE_COMBAT] Expected wars_active >= 1, got $warsActive" }
    if ($rebellionsTotal -lt 1) { throw "[SMOKE_COMBAT] Expected rebellions_total >= 1, got $rebellionsTotal" }
    if ($waterStranded -ne 0) { throw "[SMOKE_COMBAT] Expected water_stranded == 0, got $waterStranded" }
    if ($combatMaxSpeed -le 40.0) { throw "[SMOKE_COMBAT] Expected max_speed > 40.0, got $combatMaxSpeed" }
    if ($combatSaveOk -ne 1) { throw "[SMOKE_COMBAT] Expected save_ok == 1, got $combatSaveOk" }
    if ($combatSw.Elapsed.TotalSeconds -ge $TimeoutSec) {
        throw "[SMOKE_COMBAT] Timing budget exceeded: $($combatSw.Elapsed.TotalSeconds)s"
    }

    $combatWorldTickStr = $combatWorldTickMs.ToString("F3", $inv)
    $combatPhysCivTickStr = $combatPhysCivTickMs.ToString("F3", $inv)
    $combatSimTickStr = $combatSimTickMs.ToString("F3", $inv)
    $combatMaxSpeedStr = $combatMaxSpeed.ToString("F2", $inv)

    if ($combatWorldTickMs -gt 1.20) {
        throw "[SMOKE_COMBAT] Stop-Kran world timing budget exceeded: world_tick_ms=$combatWorldTickStr ms (> 1.20 ms/tick)"
    }
    if ($combatPhysCivTickMs -gt 2.50) {
        throw "[SMOKE_COMBAT] Stop-Kran phys+civ timing budget exceeded: phys_civ_tick_ms=$combatPhysCivTickStr ms (> 2.50 ms/tick)"
    }
    if ($combatSimTickMs -gt 3.80) {
        throw "[SMOKE_COMBAT] Stop-Kran full sim timing budget exceeded: sim_tick_ms=$combatSimTickStr ms (> 3.80 ms/tick)"
    }

    Write-Host "=== Step 8: Stage 3B War & Diplomacy Screenshot ==="
    if (Test-Path -LiteralPath $CombatShotPath) { Remove-Item -LiteralPath $CombatShotPath -Force }
    $null = Invoke-GodotGuarded -GodotArgs @("--path", "`"$ProjectDir`"", "--", "`"--shot-combat=$CombatShotPath`"") -Label "COMBAT_SHOT"
    $combatShotBytes = Assert-ShotValid -Path $CombatShotPath -Label "COMBAT_SHOT" -MinBytes 102400 -CheckColorVariance

    $activeGodotPre = @(Get-Process -Name "Godot*" -ErrorAction SilentlyContinue).Count
    if ($activeGodotPre -ne 0) {
        throw "Active Godot processes remaining after Step 8: $activeGodotPre"
    }

    $maxSpeedStr = $smokeMaxSpeed.ToString("F2", $inv)
    $storageStr = $storageTotal.ToString("F2", $inv)
    Write-Host ("VERIFY_ALL_PASS units={0} flora={1} max_speed={2} cities={3} zones_owned={4} buildings={5} tech_tier={6} storage_total={7} shuttles_total={8} cosmic_age={9} shield_pylons={10} shield_blocked={11} dodges={12} possession_ok={13} world_tick_ms={14} phys_civ_tick_ms={15} sim_tick_ms={16} beams_fired={17} portal_transfers={18} casualties={19} combat_tech_tier={20} wars_active={21} rebellions_total={22} water_stranded={23} combat_max_speed={24} combat_world_tick_ms={25} combat_phys_civ_tick_ms={26} combat_sim_tick_ms={27} macro_bytes={28} zoom_bytes={29} civ_bytes={30} night_bytes={31} combat_bytes={32}" -f `
        $smokeUnits, $smokeFlora, $maxSpeedStr, $cities, $zonesOwned, $buildings, $techTier, $storageStr, $shuttlesTotal, $cosmicAge, $shieldPylons, $shieldBlocked, $dodges, $possessionOk, $worldTickStr, $physCivTickStr, $simTickStr, $beamsFired, $portalTransfers, $casualties, $combatTechTier, $warsActive, $rebellionsTotal, $waterStranded, $combatMaxSpeedStr, $combatWorldTickStr, $combatPhysCivTickStr, $combatSimTickStr, $macroBytes, $zoomBytes, $civBytes, $nightBytes, $combatShotBytes)
}
finally {
    Stop-StrayGodot
}

$activeGodotFinal = @(Get-Process -Name "Godot*" -ErrorAction SilentlyContinue).Count
Write-Host ("ACTIVE_GODOT={0}" -f $activeGodotFinal)
if ($activeGodotFinal -ne 0) {
    throw "Expected ACTIVE_GODOT=0 at script exit, got $activeGodotFinal"
}
