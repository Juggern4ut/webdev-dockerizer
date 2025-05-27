<?php
if (extension_loaded('imagick')) {
    $image = new Imagick();
    $image->newImage(100, 100, new ImagickPixel('red'));
    $image->setImageFormat("png");
    header("Content-Type: image/png");
    echo $image;
} else {
    echo "ImageMagick (imagick) is NOT installed or enabled.";
}
?>
