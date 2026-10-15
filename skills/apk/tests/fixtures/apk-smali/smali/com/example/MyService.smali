.class public final Lcom/example/MyService;
.super Landroid/app/Service;
.source "MyService.kt"


# annotations
.annotation system Ldalvik/annotation/SourceDebugExtension;
    value = "SMAP\nMyService.kt\n"
.end annotation

.annotation runtime Lkotlin/Metadata;
    d1 = {
        "\u0000\u0010\n\u0002\u0018\u0002"
    }
    k = 0x1
    mv = {
        0x2,
        0x0,
        0x0
    }
.end annotation


# instance fields
.field private cacheSize:I


# direct methods
.method public constructor <init>()V
    .registers 1

    invoke-direct {p0}, Landroid/app/Service;-><init>()V

    return-void
.end method

.method private final clearAll()V
    .registers 2

    const/4 v0, 0x0

    iput v0, p0, Lcom/example/MyService;->cacheSize:I

    return-void
.end method

.method private final trimCaches(I)V
    .registers 3

    const/16 v0, 0x3c

    if-lt p1, v0, :cond_7

    invoke-direct {p0}, Lcom/example/MyService;->clearAll()V

    :cond_7
    invoke-direct {p0}, Lcom/example/MyService;->clearAll()V

    return-void
.end method


# virtual methods
.method public onCreate()V
    .registers 1

    invoke-super {p0}, Landroid/app/Service;->onCreate()V

    return-void
.end method

.method public onTrimMemory(I)V
    .registers 2

    invoke-super {p0, p1}, Landroid/app/Service;->onTrimMemory(I)V

    invoke-direct {p0, p1}, Lcom/example/MyService;->trimCaches(I)V

    return-void
.end method
