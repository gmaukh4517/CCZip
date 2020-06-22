//
//  CCArchive.m
//  CCZip
//
// Copyright (c) 2015 CC ( https://github.com/gmaukh4517/CCKit )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import "CCArchive.h"
#import "CCArchiveEntry.h"
#import "zip.h"
#include <sys/stat.h>
#include <sys/types.h>

#define ZIP_DISABLE_DEPRECATED 1

NSString *const CCArchiveErrorDomain = @"com.cc.Error.CCArchive";

const int kCCCouldNotOpenZip = 1001;
const int kCCCouldNotSaveZip = 1002;
const int kCCCouldNotOpenZippedFile = 1003;
const int kCCCouldNotReadZippedFile = 1004;
const int kCCInvalidZippedFileInfo = 1005;
const int kCCCouldNotAddZippedFile = 1006;
const int kCCCouldNotReplaceZippedFile = 1007;
const int kCCCouldNotAddZippedFolder = 1008;

@interface CCArchiveEntry (Protected)

+ (CCArchiveEntry *)zippedFileInfoWithArchive:(struct zip *)archive filePath:(NSString *)filePath options:(CCOptionsFile)options error:(NSError **)error;
- (CCArchiveEntry *)initFileInfoWithArchive:(struct zip *)archive filePath:(NSString *)filePath options:(CCOptionsFile)options error:(NSError **)error;

+ (CCArchiveEntry *)zippedFileInfoWithArchive:(struct zip *)archive index:(NSUInteger)index options:(CCOptionsFile)options error:(NSError **)error;
- (CCArchiveEntry *)initFileInfoWithArchive:(struct zip *)archive index:(NSUInteger)index options:(CCOptionsFile)options error:(NSError **)error;

@end

@interface CCArchive ()

@property (nonatomic, copy) NSURL *URL;

@property (nonatomic, assign) NSInteger fileCount;

@property (nonatomic, assign) struct zip *za;

@end

@implementation CCArchive

+ (CCArchive *)archiveWithURL:(NSURL *)fileURL error:(NSError **)error;
{
    return [[CCArchive alloc] initWithURL:fileURL options:0 error:error];
}

+ (CCArchive *)archiveWithURL:(NSURL *)fileURL options:(CCOptions)options error:(NSError **)error;
{
    return [[CCArchive alloc] initWithURL:fileURL options:options error:error];
}

- (CCArchive *)initWithURL:(NSURL *)fileURL error:(NSError **)error;
{
    return [self initWithURL:fileURL options:0 error:error];
}

- (CCArchive *)initWithURL:(NSURL *)fileURL options:(CCOptions)options error:(NSError **)error;
{
    return [self initWithPath:fileURL.path options:options error:error];
}

- (CCArchive *)initWithPath:(NSString *)filePath options:(CCOptions)options error:(NSError **)error
{
    if (self = [super init]) {
        _URL = [NSURL URLWithString:filePath];
        
        // NOTE: We could rewrite this using file descriptors.
        const char *zip_file_path = [filePath UTF8String];
        int err;
        _za = zip_open(zip_file_path, options, &err);
        if (!_za) {
            if (error) {
                char errstr[ 1024 ];
                zip_error_to_str(errstr, sizeof(errstr), err, errno);
                *error = [CCArchive error:[NSString stringWithFormat:NSLocalizedString(@"The zip archive “%@” could not be opened: %s", @"Cannot open zip archive"),
                                           filePath, errstr]
                                     code:kCCCouldNotOpenZip];
            }
            return nil;
        }
    }
    
    return self;
}

- (void)dealloc
{
    self.URL = nil;
    
    if (_za != NULL) {
        zip_unchange_all(_za);
        zip_close(_za);
        _za = NULL;
    }
}

- (NSInteger)fileCount
{
    if (!_fileCount) {
        if (!_za) return NSNotFound;
        // The underlying library uses an int to store the count so this is safe in any case.
        _fileCount = (NSInteger)zip_get_num_entries(_za, ZIP_FL_UNCHANGED);
    }
    return _fileCount;
}

- (CCArchiveEntry *)archiveFileWithIndex:(NSUInteger)index error:(NSError **)error;
{
    return [CCArchiveEntry zippedFileInfoWithArchive:_za index:index options:0 error:error];
}

- (CCArchiveEntry *)archiveFileWithIndex:(NSUInteger)index options:(CCOptionsFile)options error:(NSError **)error;
{
    return [CCArchiveEntry zippedFileInfoWithArchive:_za index:index options:options error:error];
}

- (CCArchiveEntry *)archiveWithFilePath:(NSString *)filePath error:(NSError **)error;
{
    return [CCArchiveEntry zippedFileInfoWithArchive:_za filePath:filePath options:0 error:error];
}

- (CCArchiveEntry *)archiveWithFilePath:(NSString *)filePath options:(CCOptionsFile)options error:(NSError **)error;
{
    return [CCArchiveEntry zippedFileInfoWithArchive:_za filePath:filePath options:options error:error];
}

- (NSData *)dataForFileAtIndex:(NSUInteger)index error:(NSError **)error;
{
    return [self dataForFileAtIndex:index options:0 error:error];
}

- (NSData *)dataForFileAtIndex:(NSUInteger)index options:(CCOptionsFile)options error:(NSError **)error;
{
    CCArchiveEntry *zippedFileInfo = [self archiveFileWithIndex:index error:error];
    if (zippedFileInfo == nil)
        return nil;
    else
        return [self dataForZippedFileInfo:zippedFileInfo options:0 error:error];
}

- (NSData *)dataForFilePath:(NSString *)filePath error:(NSError **)error;
{
    return [self dataForFilePath:filePath options:0 error:error];
}

- (NSData *)dataForFilePath:(NSString *)filePath options:(CCOptionsFile)options error:(NSError **)error;
{
    CCArchiveEntry *zippedFileInfo = [self archiveWithFilePath:filePath error:error];
    if (zippedFileInfo == nil)
        return nil;
    else
        return [self dataForZippedFileInfo:zippedFileInfo options:0 error:error];
}

- (NSData *)dataForZippedFileInfo:(CCArchiveEntry *)zippedFileInfo error:(NSError **)error;
{
    return [self dataForZippedFileInfo:zippedFileInfo options:0 error:error];
}

- (NSData *)dataForZippedFileInfo:(CCArchiveEntry *)zippedFileInfo options:(CCOptionsFile)options error:(NSError **)error;
{
    if (zippedFileInfo == nil) return nil;
    
    zip_uint64_t zipped_file_index = zippedFileInfo.index;
    zip_uint64_t zipped_file_size = zippedFileInfo.size;
    
    if ((zipped_file_index == NSNotFound) || (zipped_file_size == NSNotFound)) {
        if (error)
            *error = [CCArchive error:[NSString stringWithFormat:NSLocalizedString(@"Invalid zipped file info.", @"Invalid zipped file info")] code:kCCInvalidZippedFileInfo];
        return nil;
    }
    
    struct zip_file *zipped_file = zip_fopen_index(_za, zipped_file_index, (options & ZIP_FL_ENC_UTF_8));
    if (!zipped_file) {
        if (error) {
            *error = [CCArchive error:[NSString stringWithFormat:NSLocalizedString(@"Could not open zipped file “%@” in archive “%@”: %s", @"Could not open zipped file"),
                                       zippedFileInfo.path, self.URL, zip_strerror(_za)]
                                 code:kCCCouldNotOpenZippedFile];
        }
        
        return nil;
    }
    
    char *buf = malloc((size_t)zipped_file_size); // freed by NSData
    
    zip_int64_t n = zip_fread(zipped_file, buf, zipped_file_size);
    if (n < (zip_int64_t)zipped_file_size) {
        if (error) {
            *error = [CCArchive error:[NSString stringWithFormat:NSLocalizedString(@"Error while reading zipped file “%@” in archive “%@”: %s", @"Error while reading zipped file"),
                                       zippedFileInfo.path, self.URL, zip_file_strerror(zipped_file)]
                                 code:kCCCouldNotReadZippedFile];
        }
        
        zip_fclose(zipped_file);
        
        free(buf);
        
        return nil;
    }
    
    zip_fclose(zipped_file);
    
    return [NSData dataWithBytesNoCopy:buf length:(NSUInteger)zipped_file_size freeWhenDone:YES];
}

- (BOOL)addFolderWithPath:(NSString *)folderPath error:(NSError **)error
{
    if (!folderPath) return NO;
    
    const char *folder_path = [folderPath UTF8String];
    zip_int64_t index;
    if (((index = zip_dir_add(_za, folder_path, (ZIP_FL_ENC_UTF_8))) < 0)) {
        if (error) {
            *error = [CCArchive error:[NSString stringWithFormat:NSLocalizedString(@"Error while adding zipped folder “%@” in archive “%@”: %s", @"Error while adding zipped folder"),
                                       folderPath, self.URL, zip_strerror(_za)]
                                 code:kCCCouldNotAddZippedFolder];
        }
        return NO;
    }
    return YES;
}

- (BOOL)addFileWithPath:(NSString *)filePath forData:(NSData *)data error:(NSError **)error;
{
    if ((filePath == nil) || (data == nil)) return NO;
    
    // CHANGEME: Passing the index back might be helpful
    
    const char *file_path = [filePath UTF8String];
    struct zip_source *file_zip_source = zip_source_buffer(_za, [data bytes], [data length], 0);
    zip_int64_t index;
    
    if ((file_zip_source == NULL) || ((index = zip_file_add(_za, file_path, file_zip_source, (ZIP_FL_ENC_UTF_8))) < 0)) {
        if (error) {
            *error = [CCArchive error:[NSString stringWithFormat:NSLocalizedString(@"Error while adding zipped file “%@” in archive “%@”: %s", @"Error while adding zipped file"),
                                       filePath, self.URL, zip_strerror(_za)]
                                 code:kCCCouldNotAddZippedFile];
        }
        
        if (file_zip_source) zip_source_free(file_zip_source);
        
        return NO;
    }
    
    return YES;
}

- (BOOL)replaceFile:(CCArchiveEntry *)zippedFileInfo withData:(NSData *)data error:(NSError **)error;
{
    if ((zippedFileInfo == nil) || (data == nil)) return NO;
    
    struct zip_source *file_zip_source = zip_source_buffer(_za, [data bytes], [data length], 0);
    
    if ((file_zip_source == NULL) || (zip_file_replace(_za, zippedFileInfo.index, file_zip_source, 0) < 0)) {
        if (error) {
            *error = [CCArchive error:[NSString stringWithFormat:NSLocalizedString(@"Error while replacing zipped file “%@” in archive “%@”: %s", @"Error while replacing zipped file"),
                                       zippedFileInfo.path, self.URL, zip_strerror(_za)]
                                 code:kCCCouldNotReplaceZippedFile];
        }
        
        if (file_zip_source) zip_source_free(file_zip_source);
        
        return NO;
    }
    
    // We don’t need to zip_source_free() here, as libzip has taken care of it once we have reached this line.
    
    return YES;
}


+ (BOOL)zipFileAtPath:(NSString *)filePath toFilePath:(NSString *)toFilePath error:(NSError **)error
{
    NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:filePath];
    NSString *filePathName;
    int err = 0;
    const char *zip_file_path = [toFilePath UTF8String];
    struct zip *zipfile = zip_open(zip_file_path, ZIP_CREATE | ZIP_TRUNCATE, &err);
    if (zipfile) {
        struct zip_source *srcfile = NULL;
        while (filePathName = [dirEnum nextObject]) {
            const char *sourceFilePath = [[filePath stringByAppendingPathComponent:filePathName] UTF8String];
            struct stat st;
            stat(sourceFilePath, &st);
            if (S_ISDIR(st.st_mode)) {
                zip_dir_add(zipfile, [filePathName UTF8String], ZIP_FL_ENC_GUESS);
            } else if (S_ISREG(st.st_mode)) {
                srcfile = zip_source_file(zipfile, sourceFilePath, 0, -1);
                if (srcfile) {
                    zip_file_add(zipfile, [filePathName UTF8String], srcfile, ZIP_FL_OVERWRITE);
                }
            }
        }
        
        if (zip_close(zipfile) < 0) {
            if (error) {
                *error = [CCArchive error:[NSString stringWithFormat:NSLocalizedString(@"The zip archive “%@” could not be saved: %s", @"Cannot save zip archive"),
                                           toFilePath, zip_strerror(zipfile)]
                                     code:kCCCouldNotSaveZip];
            }
        }
    } else {
        if (error) {
            char errstr[ 1024 ];
            zip_error_to_str(errstr, sizeof(errstr), err, errno);
            *error = [CCArchive error:[NSString stringWithFormat:NSLocalizedString(@"The zip archive “%@” could not be opened: %s", @"Cannot open zip archive"),
                                       toFilePath, errstr]
                                 code:kCCCouldNotOpenZip];
        }
    }
    
    return YES;
}

+ (BOOL)unzipFIleAtpath:(NSString *)zipPath toZipPath:(NSString *)toZipPath error:(NSError **)error
{
    BOOL isSuccess = NO;
    const char *zip_file_path = [zipPath UTF8String];
    int err;
    struct zip *zipfile = zip_open(zip_file_path, ZIP_CHECKCONS, &err);
    if (zipfile) {
        NSInteger fileCount = (NSInteger)zip_get_num_entries(zipfile, ZIP_FL_UNCHANGED);
        struct zip_stat stat;
        struct zip_file *entries = NULL;
        
        char *toPath = (char *)[toZipPath UTF8String];
        if ((toPath)[ strlen((toPath)) - 1 ] != '/')
            strcat((toPath), "/");
        
        for (NSInteger index = 0; index < fileCount; index++) {
            zip_stat_index(zipfile, index, 0, &stat);
            entries = zip_fopen_index(zipfile, index, 0);
            if (!entries) break;
            
            char zipPath[ 256 ];
            strcpy(zipPath, toPath);
            strcat(zipPath, stat.name);
            if (access(zipPath, F_OK) == -1) {
                char DirName[ 256 ];
                strcpy(DirName, zipPath);
                unsigned long len = strlen(DirName);
                len = strlen(DirName);
                for (int i = 1; i < len; i++) {
                    if (DirName[ i ] == '/') {
                        DirName[ i ] = 0;
                        if (access(DirName, F_OK) != 0) {
                            if (mkdir(DirName, S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH) == -1) {
                                perror("mkdir error");
                                break;
                            }
                        }
                        DirName[ i ] = '/';
                    }
                }
            }
            
            //create the original file
            FILE *fp = fopen(zipPath, "w+");
            if (fp) {
                zip_int64_t iRead = 0;
                int iLen = 0;
                char outbuf[ 1024 ];
                while (iLen < stat.size) {
                    iRead = zip_fread(entries, outbuf, 1024);
                    if (iRead < 0)
                        fclose(fp);
                    fwrite(outbuf, 1, (unsigned long)iRead, fp);
                    iLen += iRead;
                }
                
                fclose(fp);
            }
        }
        
        if (zip_close(zipfile) < 0) {
            if (error) {
                *error = [CCArchive error:[NSString stringWithFormat:NSLocalizedString(@"The zip archive “%@” could not be saved: %s", @"Cannot save zip archive"),
                                           zipPath, zip_strerror(zipfile)]
                                     code:kCCCouldNotSaveZip];
            }
        }
    } else {
        if (error) {
            char errstr[ 1024 ];
            zip_error_to_str(errstr, sizeof(errstr), err, errno);
            *error = [CCArchive error:[NSString stringWithFormat:NSLocalizedString(@"The zip archive “%@” could not be opened: %s", @"Cannot open zip archive"),
                                       zipPath, errstr]
                                 code:kCCCouldNotOpenZip];
        }
    }
    
    
    return isSuccess;
}

- (BOOL)saveAndReturnError:(NSError **)error;
{
    if (!_za) return NO;
    
    if (zip_close(_za) < 0) {
        if (error) {
            *error = [CCArchive error:[NSString stringWithFormat:NSLocalizedString(@"The zip archive “%@” could not be saved: %s", @"Cannot save zip archive"),
                                       self.URL, zip_strerror(_za)]
                                 code:kCCCouldNotSaveZip];
        }
        
        return NO;
    } else {
        _za = NULL;
        return YES;
    }
}

+ (NSError *)error:(NSString *)errorDescription code:(NSInteger)code
{
    NSDictionary *errorDetail = @{NSLocalizedDescriptionKey : errorDescription};
    return [NSError errorWithDomain:CCArchiveErrorDomain code:code userInfo:errorDetail];
}


@end
