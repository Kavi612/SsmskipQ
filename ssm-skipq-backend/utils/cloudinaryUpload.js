import { Readable } from 'stream';
import cloudinary from '../config/cloudinary.js';

export const uploadImageBuffer = (buffer, folder = 'ssm-skipq/menu') =>
  new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(
      { folder, resource_type: 'image' },
      (error, result) => {
        if (error) reject(error);
        else resolve(result);
      },
    );
    Readable.from(buffer).pipe(stream);
  });

export const deleteCloudinaryImage = async (imageUrl) => {
  if (!imageUrl) return;
  try {
    const match = imageUrl.match(/\/upload\/(?:v\d+\/)?(.+)\.\w+$/);
    if (match?.[1]) {
      await cloudinary.uploader.destroy(match[1]);
    }
  } catch {
    // Non-fatal if cleanup fails
  }
};
