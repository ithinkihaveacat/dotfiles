.class public final Lcom/example/MyWidgetService;
.super Lcom/example/lib/WidgetService;
.source "MyWidgetService.kt"


# annotations
.annotation runtime Lcom/example/lib/AssociateWith;
    value = Lcom/example/MyWidget;
.end annotation

.annotation runtime Lkotlin/Metadata;
    k = 0x1
.end annotation


# instance fields
.field public repository:Lcom/example/Repository;
    .annotation runtime Ljavax/inject/Inject;
    .end annotation
.end field

.field private started:Z


# direct methods
.method public constructor <init>()V
    .registers 1

    invoke-direct {p0}, Lcom/example/lib/WidgetService;-><init>()V

    return-void
.end method


# virtual methods
.method public getWidget()Lcom/example/lib/Widget;
    .registers 2
    .annotation build Landroidx/annotation/VisibleForTesting;
    .end annotation

    .param p0    # Lcom/example/MyWidgetService;
        .annotation build Lorg/jetbrains/annotations/NotNull;
        .end annotation
    .end param

    new-instance v0, Lcom/example/MyWidget;

    invoke-direct {v0}, Lcom/example/MyWidget;-><init>()V

    return-object v0
.end method
