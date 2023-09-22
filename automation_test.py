import subprocess

while True:

    function_name = input("Yapilacak Islemi Yazin: ")
    image_index = int(input("Gecerli bir gorsel numarası girin (0 ile 10 arasında): "))

    if 0 <= image_index <= 10:

        if function_name.lower() == "gurultusuz":
            result = subprocess.check_output(r"processing-java --sketch=DenoiseImage --run test_image_"
                                             + str(image_index) + ".jpg", shell=True)
            break

        elif function_name.lower() == "blursuz":
            result = subprocess.check_output(r"processing-java --sketch=DeblurImage --run test_image_"
                                             + str(image_index) + ".jpg", shell=True)
            break

        elif function_name.lower() == "blur gurultu":
            result = subprocess.check_output(r"processing-java --sketch=BlurAndNoise --run test_image_"
                                             + str(image_index) + ".jpg", shell=True)
            break

    print("Tekrar Deneyin\n")
