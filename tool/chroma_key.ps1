# Chroma-key tool: removes a solid #00FF00 green-screen background from a PNG,
# despills green fringes on edges, trims transparent borders, and saves a
# transparent PNG. Used to convert Gemini-generated pet art (which cannot output
# alpha) into game-ready sprites.
#
# Usage: powershell -File tool\chroma_key.ps1 -In <input.png> -Out <output.png>
param(
  [Parameter(Mandatory = $true)][string]$In,
  [Parameter(Mandatory = $true)][string]$Out
)

Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class ChromaKey {
  public static void Run(string inPath, string outPath) {
    using (var src = new Bitmap(inPath))
    using (var bmp = new Bitmap(src.Width, src.Height, PixelFormat.Format32bppArgb)) {
      using (var g = Graphics.FromImage(bmp)) g.DrawImage(src, 0, 0, src.Width, src.Height);

      var rect = new Rectangle(0, 0, bmp.Width, bmp.Height);
      var data = bmp.LockBits(rect, ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
      int bytes = Math.Abs(data.Stride) * bmp.Height;
      byte[] buf = new byte[bytes];
      Marshal.Copy(data.Scan0, buf, 0, bytes);

      for (int i = 0; i < bytes; i += 4) {
        byte b = buf[i], gch = buf[i + 1], r = buf[i + 2];
        int maxRB = Math.Max(r, b);
        int diff = gch - maxRB;          // how much greener than anything else
        if (diff > 88) {
          buf[i + 3] = 0;                 // solid green -> fully transparent
        } else if (diff > 28) {
          // Edge zone: partial alpha + despill (pull green down to neighbors)
          double t = (diff - 28) / 60.0;  // 0..1
          buf[i + 3] = (byte)Math.Max(0, Math.Min(255, (int)(buf[i + 3] * (1.0 - t))));
          buf[i + 1] = (byte)maxRB;
        } else if (gch > maxRB + 12) {
          // Mild green cast on opaque pixels -> gentle despill only
          buf[i + 1] = (byte)(maxRB + 12);
        }
      }

      Marshal.Copy(buf, data.Scan0, bytes, bytes == 0 ? 0 : bytes);
      bmp.UnlockBits(data);

      // Trim transparent borders (keep a small margin)
      int minX = bmp.Width, minY = bmp.Height, maxX = -1, maxY = -1;
      var data2 = bmp.LockBits(rect, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
      byte[] buf2 = new byte[bytes];
      Marshal.Copy(data2.Scan0, buf2, 0, bytes);
      bmp.UnlockBits(data2);
      int stride = Math.Abs(data2.Stride);
      for (int y = 0; y < bmp.Height; y++) {
        for (int x = 0; x < bmp.Width; x++) {
          if (buf2[y * stride + x * 4 + 3] > 8) {
            if (x < minX) minX = x;
            if (x > maxX) maxX = x;
            if (y < minY) minY = y;
            if (y > maxY) maxY = y;
          }
        }
      }
      if (maxX < 0) { bmp.Save(outPath, ImageFormat.Png); return; }
      int margin = 6;
      minX = Math.Max(0, minX - margin); minY = Math.Max(0, minY - margin);
      maxX = Math.Min(bmp.Width - 1, maxX + margin); maxY = Math.Min(bmp.Height - 1, maxY + margin);
      var cropRect = new Rectangle(minX, minY, maxX - minX + 1, maxY - minY + 1);
      using (var cropped = bmp.Clone(cropRect, PixelFormat.Format32bppArgb)) {
        cropped.Save(outPath, ImageFormat.Png);
      }
    }
  }
}
"@

[ChromaKey]::Run((Resolve-Path $In).Path, $Out)
Write-Output "keyed: $Out ($((Get-Item $Out).Length) bytes)"
