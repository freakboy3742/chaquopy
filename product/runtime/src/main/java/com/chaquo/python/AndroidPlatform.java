package com.chaquo.python;

import android.content.*;
import android.content.res.*;

import java.io.*;


/** Platform for Chaquopy on Android. */
public class AndroidPlatform implements Python.Platform {
    private static final String NAME = "chaquopy";
    private static final String STDLIB_FILENAME = "stdlib.zip";

    private Context mContext;

    public AndroidPlatform(Context context) {
        mContext = context;
        extractAssets();
        loadNativeLibs();
    }

    @Override
    public String getPath() {
        return new File(getFilesDir(), STDLIB_FILENAME).getAbsolutePath();
    }

    private void extractAssets() {
        // TODO detect if the packaged assets have changed (maybe with embedded version number),
        // and re-extract if so (Unclear whether FileOutputStream truncates, so delete first.)
        try {
            AssetManager assets = mContext.getAssets();
            for (String filename : assets.list(NAME)) {
                File outFile = new File(getFilesDir(), filename);
                if (!outFile.exists()) {
                    InputStream inStream = assets.open(filename);
                    File tmpFile = new File(outFile.getParent(), outFile.getName() + ".tmp");
                    OutputStream outStream = new FileOutputStream(tmpFile);
                    try {
                        transferStream(inStream, outStream);
                    } finally {
                        outStream.close();
                    }
                    if (! tmpFile.renameTo(outFile)) {
                        throw new IOException("Failed to create " + outFile);
                    }
                }
            }
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    private void transferStream(InputStream in, OutputStream out) throws IOException {
        byte[] buffer = new byte[1024 * 1024];
        int len = in.read(buffer);
        while (len != -1) {
            out.write(buffer, 0, len);
            len = in.read(buffer);
        }
    }


    private File getFilesDir() {
        File filesDir = new File(mContext.getFilesDir(), NAME);
        if (! filesDir.exists()) {
            filesDir.mkdirs();
            if (! filesDir.isDirectory()) {
                throw new RuntimeException("Failed to create " + filesDir);
            }
        }
        return filesDir;
    }

    private void loadNativeLibs() {
        // Libraries must be loaded in reverse dependency order before API level 18: see
        // https://developer.android.com/ndk/guides/cpp-support.html
        System.loadLibrary("crystax");
        System.loadLibrary("python2.7");  // TODO #5148
        System.loadLibrary("chaquopy_java");
    }

}