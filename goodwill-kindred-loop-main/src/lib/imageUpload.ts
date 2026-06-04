// Client-side image -> resized base64 data URL.
// Keeps total payload under ~600KB so it fits the server validator.
export async function fileToDataUrl(file: File, maxDim = 1280, quality = 0.82): Promise<string> {
  if (!file.type.startsWith("image/")) throw new Error("Please pick an image.");
  const url = URL.createObjectURL(file);
  try {
    const img = await new Promise<HTMLImageElement>((res, rej) => {
      const i = new Image();
      i.onload = () => res(i);
      i.onerror = () => rej(new Error("Could not read image."));
      i.src = url;
    });
    const ratio = Math.min(1, maxDim / Math.max(img.width, img.height));
    const w = Math.round(img.width * ratio);
    const h = Math.round(img.height * ratio);
    const canvas = document.createElement("canvas");
    canvas.width = w;
    canvas.height = h;
    const ctx = canvas.getContext("2d")!;
    ctx.drawImage(img, 0, 0, w, h);
    let q = quality;
    let data = canvas.toDataURL("image/jpeg", q);
    while (data.length > 600_000 && q > 0.35) {
      q -= 0.12;
      data = canvas.toDataURL("image/jpeg", q);
    }
    return data;
  } finally {
    URL.revokeObjectURL(url);
  }
}
