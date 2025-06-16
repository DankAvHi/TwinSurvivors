using System;
using Godot;

public partial class Player : CharacterBody2D
{
    public const float Speed = 300.0f;
    private AnimatedSprite2D animatedSprite;

    public override void _Ready()
    {
        animatedSprite = GetNode<AnimatedSprite2D>("AnimatedSprite2D");
    }

    public override void _PhysicsProcess(double delta)
    {
        Vector2 velocity = Velocity;

        Vector2 direction = Input.GetVector("ui_left", "ui_right", "ui_up", "ui_down");
        if (direction != Vector2.Zero)
        {
            velocity = direction * Speed;
            animatedSprite.Play("default");
        }
        else
        {
            velocity = Vector2.Zero;
            animatedSprite.Stop();
        }

        Velocity = velocity;
        MoveAndSlide();
    }
}
