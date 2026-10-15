.class public final Lcom/example/OtherWidgetService;
.super Lcom/example/lib/WidgetService;
.source "SourceFile"


# annotations
.annotation runtime La/b;
    value = Lcom/example/OtherWidget;
.end annotation


# direct methods
.method public constructor <init>()V
    .registers 1

    invoke-direct {p0}, Lcom/example/lib/WidgetService;-><init>()V

    return-void
.end method


# virtual methods
.method public final forward(Landroid/content/ComponentCallbacks2;I)V
    .registers 3

    invoke-interface {p1, p2}, Landroid/content/ComponentCallbacks2;->onTrimMemory(I)V

    return-void
.end method
