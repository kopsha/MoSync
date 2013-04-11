/*
 Copyright (C) 2013 MoSync AB

 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License,
 version 2, as published by the Free Software Foundation.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 MA 02110-1301, USA.
 */

/**
 * @file ImageViewerScreen.h
 * @author Mircea Vasiliniuc
 * @date 16 March 2013
 *
 * @brief Screen that displays an image.
 */

#ifndef SNAPSHOTSCREEN_H_
#define SNAPSHOTSCREEN_H_

#include <NativeUI/Screen.h>
#include <NativeUI/ButtonListener.h>

namespace NativeUI
{
	class RelativeLayout;
	class ImageButton;
	class Image;
}

namespace MoSyncCamera
{
	// TODO: this class name indicates that is an observer, but I'm having a
	// hard time imagining what's the object of the observation, because I
	// find 3 nouns: Image, Viewer, Screen // maybe 2 ImageViewer, Screen
	class ImageViewerScreenObserver
	{
	public:
		/**
		 * Notifies the observer to dismiss the screen
		 * displaying the snapshot.
		 */
		// TODO continued: then I see what's the notification about
		virtual void dismissSnapshot() {};	// Q: Should this be pure virtual?
	};

	class ImageViewerScreen:
		public NativeUI::Screen,
		public NativeUI::ButtonListener
	{
	public:
		/**
		 * Constructor.
		 *
		 * @param observer Observer for this screen.
		 */
		// FIXME: I would explain why this observer is required
		ImageViewerScreen(ImageViewerScreenObserver& observer);

		~ImageViewerScreen();

        /**
         * This method is called if the touch-up event was inside the
         * bounds of the button.
         * Platform: iOS, Android, Windows Phone.
         * @param button The button object that generated the event.
         */
        void buttonClicked(NativeUI::Widget* button);	// FIXME: make this virtual

        /**
		 * Sets the displayed image using the diven data.
		 * @param imageDataHandle Snapshot image data handle.
		 */
        void setImageWithData(const MAHandle& imageDataHandle);

	private:
		/** FIXME: remove
		 * Create screen's UI.
		 */
        void createUI();

        /**  FIXME: remove
         * Configures the main layout.
         */
        void setupMainLayout();

        /**  FIXME: remove
         * Configures the image view and adds it
         * to the main layout.
         */
        void setupImageView();

        /**  FIXME: remove
         * Configures the image viewer buttons and
         * adds them to the main layout.
         */
        void setupButtons();

        /**  FIXME: remove
         * Arranges the widgets on the layout.
         */
        void arrangeWidgets();

	private:
		/**  FIXME: remove
		 * Observer for this screen.
		 */
        ImageViewerScreenObserver& mObserver;	// FIXME: is mScreenObserver a better name for this?

		/**  FIXME: remove
		 * Layout used to hold images.
		 */
		NativeUI::RelativeLayout* mMainLayout;

		/**  FIXME: remove
		 * Camera.
		 */
		NativeUI::Image* mImageView;

		/**  FIXME: remove
		 * Button that dismisses the screen.
		 */
		NativeUI::ImageButton* mDismissButton;

		/**  FIXME: remove
		 * Button that saves the image viewed.
		 */
		NativeUI::ImageButton* mSaveImageButton;

		/**  FIXME: remove
		 * Handle for the image viewed.
		 */
		MAHandle mImageHandle;
	};
} // CameraDemo	 FIXME: remove
#endif /* SNAPSHOTSCREEN_H_ */
