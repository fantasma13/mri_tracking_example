## 1. general OpenCV object tracking test:

	# 1.a. opens the first frame for user interaction: draw a ROI.
		./opencv_trackVideo 1 ../data/results/videos/157_flash_nav_set-210526_2slc_SETTER_START_slc-1.avi

	# 1.b. runs the tracking task for the specified tracker (2) on reference frame (0) with a predefined bounding-box (51 37 28 32), without silent-mode (0) but saving the resulting video (1):
		./opencv_trackVideo 1 ../data/results/videos/157_flash_nav_set-210526_2slc_SETTER_START_slc-1.avi  2 0  51 37 28 32  0 1
	

## 2. testing of the functions/files prepared for matlab implementation:
	# 2.a. opens the first frame for user interaction: draw a ROI.
	./test_tracking4matlab 1 ../data/results/videos/157_flash_nav_set-210526_2slc_SETTER_START_slc-1.avi

	# 2.b. runs the tracking task for the specified tracker (2) on reference frame (0) with a predefined bounding-box (51 37 28 32), without silent-mode (0) but saving the resulting video (1):
	./test_tracking4matlab 1 ../data/results/videos/157_flash_nav_set-210526_2slc_SETTER_START_slc-1.avi  2 0  51 37 28 33  0 1


