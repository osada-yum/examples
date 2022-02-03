program coarrays_test
  implicit none
  integer :: my_image, n_images
  my_image = this_image()
  n_images = num_images()
  print*, "I'm ", my_image, "/", n_images
end program coarrays_test
